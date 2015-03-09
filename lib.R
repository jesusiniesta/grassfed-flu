
#setwd("~/proyecto")
#setwd("C:/Users/ikun/Dropbox/proyecto")

library(ggplot2)
library(maps)
library(igraph)
library(data.table)
library(dplyr)
library(splitstackshape)

###################################################################################
# AUX CODE

printf <- function(...) invisible(print(sprintf(...)))

PrintTime <- function (name, t0)
{
  # prints time since t0, to measure how much `name` took
  # t0 <- proc.time()
  # do.serious.shit(data)
  # PrintTime("Foo", t0)
  print(sprintf("%s took %gs\n", name, (proc.time()-t0)[[3]] ))  
}

Cut2 <- function(x, breaks) 
{
  # makes boxes, and represents them by their mean
  # from http://stackoverflow.com/a/5916794/462087
  r <- range(x)
  b <- seq(r[1], r[2], length=2*breaks+1)
  brk <- b[0:breaks*2+1]
  mid <- b[1:breaks*2]
  brk[1] <- brk[1]-0.01
  k <- cut(x, breaks=brk, labels=FALSE)
  mid[k]
}


##################################################################################
# Data load

#    s4 tweet layout
#    ---------------
#     #  |  field          | explanation                        | type
#    ----|-----------------|------------------------------------|-----------
#     01 | timestamp       | seconds since Aug-01 2013          | integer
#     02 | lat             | latitude                           | double
#     03 | lon             | longitude                          | double
#     04 | user.id         | user id                            | integer
#     05 | user.name       | user name                          | character
#     06 | hashtags        | hashtags used (comma-separated)    | character
#     07 | mentions(id)    | users mentioned (by their "my_id") | character
#     08 | mentiones(name) | users_mentioned (by their name)    | character
#     09 | my_id           | new id given from 1 to |U|         | integer
#     10 | message         | tokenized message                  | character

ReadTweets <- function( raw.file = 'data/s4.201308.unsorted', 
                        rdata    = 'data/rdata/s4.201308',
                        breaks   = 4000, breaks.lat = NA, breaks.lon = NA) 
{ 
  if (!is.null(rdata) && file.exists(rdata)){
    load(rdata);
    printf("reading tweets from rdata");
    tweets
  } else {
    t0 <- proc.time();
    tweets <- data.frame( read.csv2( raw.file, sep="|", dec=".", header=T, stringsAsFactors=F ))
    
    # obtain the cells 
    tweets$boxlat <- Cut2(tweets$lat, if (is.numeric(breaks.lat)) breaks.lat else breaks);
    tweets$boxlon <- Cut2(tweets$lon, if (is.numeric(breaks.lon)) breaks.lat else breaks);
    
    save(tweets, file=rdata)
    PrintTime("reading the tweets file", t0);
    
    tweets
  }
}

Users <- function (tweets, rdata='data/rdata/users', cells=NULL)
{
  if (!is.null(rdata) && file.exists(rdata)){
    load(rdata);
    printf("reading users from rdata");
    users
  } else {
    t0 <- proc.time();
    
    u <- unique(select(tweets, user.id, user.name, my.id))
    
    # find each user's most common location
    most.common.locations <- setDT(tweets)[, .N, by=.(user.id, boxlat, boxlon)][, .SD[which.max(N)], by = user.id]
    most.common.locations <- data.frame(most.common.locations)[c("user.id","boxlat","boxlon")]
    u <- merge(u, most.common.locations) # boxlat, boxlon
    
    # read the cells frame to get our cell id
    if (!is.null(cells)) {
      u <- merge(u, cells)  # cell.id
    }
    
    PrintTime("extracting the users", t0);
    users <- u
    save(users, file=rdata)
    u
  }
}

#############################################################################
# geographical regions

ReadTowns <- function(file='data/geonames/ES.P.dat') 
{
  towns <- read.csv2(file, sep="|", header = T, dec=".",
                     colClasses=c("integer",          # geonameid
                                  "factor",           # provincia 
                                  "character",              # asciiname 
                                  "numeric", "numeric",       # latitude longitude 
                                  "factor", "factor", # featureclass featurecode 
                                  "integer"           # population
                                  ));
  towns
}
towns <- ReadTowns();

AssignTown <- (frame, towns)
{
  
}

#############################################################################
# graphs

# undirected, unweighted
ReadEdgelist <- function (el.file, as.igraph=T) 
{
  t0 <- proc.time()
  
  edgelist <- read.csv2(el.file, sep=" ", colClasses=c("integer","integer"))
  names(edgelist) <- c("a","b")
  
  x <- if (as.igraph) {
    simplify( graph.data.frame(edgelist, directed=F), 
              remove.multiple = T, 
              remove.loops = F );    
  } else {
    unique(edgelist)
  }
  
  PrintTime("G1 by closeness", t0)
  x
}

# linking users that have mutually mentioned each other.
# first we retrieve the mentions, who mentions whom.
#now we identify mutual mentions. probably not the best way, but i think this is the fastest that has come to my mind:
#(the idea is to revert the mentions graph, making the A of each edge be the B, and the B be the A; now, any edge that is repeated is a mutual mention. as an optimization, I will only revert the edges where a > b (see `mentionsA`) and compare with those where a < b (`mentionsB`).)
# G1ByMentions will return a dataframe if `as.igraph` is `F`, an igraph object if `T`.
G1ByMentions <- function(tweets, as.igraph=T)
{
  t0 <- proc.time()
  
  mentions <- unique(
    cSplit(
      indt      = select( filter( tweets, mentions.c != "") , my.id, mentions.c ),
      splitCols ="mentions.c", 
      sep       = ",", 
      direction = "long"
    )
  )
  names(mentions) <- c("a","b")
  
  # select only mutual links
  mentionsA <- rename( select ( filter(mentions, 
                                       a > b),
                                b, a),
                       b=a, a=b)
  mentionsB <- filter(mentions, a < b)
  mentionsX <- rbind(mentionsA, mentionsB)
  
  mutual.mentions <- mentionsX[duplicated(mentionsX),]
  
  if (as.igraph) {
    g1.by.mentions <- graph.data.frame(mutual.mentions, directed=F)
  } else {
    g1.by.mentions <- mutual.mentions
  }
  
  PrintTime("G1 by mutual mentions", t0)
  
  g1.by.mentions
}

G1ByHashtags <- function(tweets) 
{
  t0 <- proc.time()
  
  uh <- unique( 
    cSplit( # Split Concatenated Values into Separate Values
      indt = select( filter(tweets, hashtags.c != ""), my.id, hashtags.c),  # select user.id, hashtags.c, from tweets where hashtags.c not ""
      splitCols = "hashtags.c", 
      sep = ",", 
      direction = "long"
    )
  )
  #=> user1->hashtag1; user2->hashtag1; user1->hashtag2;... (unique)
  
  hashtag.collisions <- filter( merge(uh,uh,by="hashtags.c",allow.cartesian=T), 
                                my.id.x < my.id.y)
  
  
  g1.by.hashtag <- graph.data.frame( unique( select(hashtag.collisions, 
                                                    my.id.x, my.id.y) ), 
                                     directed=F);
  
  PrintTime("G1ByHashtags", t0);
  g1.by.hashtag
}
