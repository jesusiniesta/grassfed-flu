
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
  s <- (proc.time()-t0)[[3]];
  print(sprintf("%s took %gs\n", name,  s));
  s;
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
#  towns <- ReadTowns();

#float CalculateDistance( float nLon1, float nLat1, float nLon2, float nLat2 )
#{
#  uint nRadius = 6371; // Earth's radius in Kilometers
#    // Get the difference between our two points
#    // then convert the difference into radians
#    float nDLat = (nLat2 - nLat1) * (M_PI/180);
#    float nDLon = (nLon2 - nLon1) * (M_PI/180);
#    float nA = pow ( sin(nDLat/2), 2 ) + cos(nLat1) * cos(nLat2) * pow ( sin(nDLon/2), 2 );
# 
#    float nC = 2 * atan2( sqrt(nA), sqrt( 1 - nA ));
#    float nD = nRadius * nC;
# 
#    return nD; // Return our calculated distance
#}
#
# this is working, but it's damn slow:
# 
# > t0 <- proc.time(); assignments <- AssignTown(head(tweets, n=5000), towns); PrintTime("assigning town to 5000 tweets", t0);
# There were 50 or more warnings (use warnings() to see the first 50)
# [1] "assigning town to 15000 tweets took 135.7s\n"
# > (135.7 * dim(tweets)[1] / 15000) / (60^2)
# [1] 7.780955

AssignTown <- function (tweets, towns, speed=1)
{
  # constants
  earth.radius <- 6371
  pi180 <- pi/180
  
  foo <- function(lat, lon) {
    
    iLat <- as.numeric(lat)
    iLon <- as.numeric(lon)
    
    nDLat <- (towns$latitude  - iLat) * pi180;
    nDLon <- (towns$longitude - iLon) * pi180;
    distances.1 <- sin(nDLat/2)^2 + cos(towns$latitude) * cos(iLat) * sin(nDLon/2)^2
    distances   <- earth.radius * 2 * atan2( sqrt(distances.1), sqrt(1 - distances.1) )
    
    closest.town <- towns[which(distances == min(distances, na.rm = T)),];
    closest.town$geonameid
  }
  
  foo.faster <- function(lat, lon) 
  {
    ilat <- as.numeric(lat)
    ilon <- as.numeric(lon)
    d <- (acos(sin(ilat)*sin(towns$latitude) +
                 cos(ilat)*cos(towns$latitude) * cos(towns$longitude-ilon)) 
          * earth.radius)
    
    closest.town <- towns[which(d == min(d, na.rm = T)),];
    closest.town$geonameid
  }
  
  if (speed == 1) {
    ff <- foo;
  } else if (speed == 2) {
    ff <- foo.faster;
  }
  
  list.of.lists.of.ids <- apply(tweets, 1, function(t) ff(t['lat'],t['lon']) )
  list.of.ids <- unlist(list.of.lists.of.ids, recursive=FALSE)
  
  list.of.ids
}

if (T) {
  size=200;
  htweets <- head(tweets, n=size);

  printf("Speed 1, %d rows\n", size);
  t0 <- proc.time(); 
  assignments <- AssignTown(htweets, towns, speed=1); 
  tspan <- PrintTime("SPEED 1", t0);
  printf("The whole dataset would take %f hours\n", ((tspan * dim(tweets)[1] / size) / (60^2)));
  
  printf("Speed 2, %d rows\n", size);
  t0 <- proc.time(); 
  assignments.faster <- AssignTown(htweets, towns, speed=2); 
  tspan <- PrintTime("SPEED 2", t0);
  printf("The whole dataset would take %f hours\n", ((tspan * dim(tweets)[1] / size) / (60^2)));
  
  count.iguales <- length(which(assignments == assignments.faster));
  printf("coinciden %d de %d\n", count.iguales, length(assignments));

  htweets$geonameid <- assignments
  my.towns <- towns[towns$geonameid %in% assignments, c('geonameid', 'asciiname', 'latitude', 'longitude')]
  htweets <- merge(htweets, my.towns, by='geonameid')

  htweets$geonameid2 <- assignments.faster
  my.towns2 <- select(towns[towns$geonameid %in% assignments,],
                                   geonameid2=geonameid, asciiname2=asciiname, 
                                   latitude2=latitude, longitude2=longitude)
  htweets <- merge(htweets, my.towns2, by='geonameid2')


  errors <- select(filter(htweets, geonameid != geonameid2), longitude, latitude, asciiname, longitude2, latitude2, asciiname2)
}
