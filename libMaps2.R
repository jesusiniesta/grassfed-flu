library(sp)
library(rgeos)
library(dplyr)

# https://stackoverflow.com/questions/21977720/r-finding-closest-neighboring-point-and-number-of-neighbors-within-a-given-rad/21981693#21981693

size=5000;
htweets <- head(tweets, n=size);
mydata <- select(htweets, lat, lon, user.name);

# let's divide towns in cuts
towns$lon <- towns$longitude
towns$lat <- towns$latitude
towns$latcut <- cut(towns$lat, breaks=10) # review this, 10 might be too few cuts
sp.towns <- towns[1:10000,]
coordinates(sp.towns) <- ~longitude+latitude

# extract the levels
labs <- levels(towns$latcut)
latcuts <- data.frame(lower = as.numeric( sub("\\((.+),.*", "\\1", labs) ),
                 upper = as.numeric( sub("[^,]*,([^]]*)\\]", "\\1", labs)),
                 level.name = labs);

# assign a cut to each tweet
# TODO: crear una función que asigna a cada tweet su caja, y usar apply
mydata$latcut <- 

# create tweet coordinates
sp.mydata <- mydata
coordinates(sp.mydata) <- ~lon+lat

t0 <- proc.time(); 

# Now calculate pairwise distances between points
d <- gDistance(spgeom2=sp.mydata, spgeom1=sp.towns, byid=T)

# Find second shortest distance (closest distance is of point to itself, therefore use second shortest)
min.d <- apply(d, 1, function(x) order(x, decreasing=F)[1])

# Construct new data frame with desired variables
newdata <- cbind(mydata, towns[min.d,c("geonameid", "provincia", "asciiname", "population", "lon", "lat")])
names(newdata) <- c("lat", "lon", "user.name", "geonameid", "provincia", "asciiname", "population", "tlon", "tlat")

#colnames(newdata) <- c(colnames(mydata), "n.lat", "n.lon", "n.user.name", "n.msg", 'distance')

benchmark <- PrintTime("libMaps", t0);
expected.total.time <- (3096327*benchmark)/size
printf("for the whole dataset it'll take: %f hours\n", (expected.total.time/(60^2)));

newdata[which(abs(newdata$lat - newdata$tlat)>3),]
max(abs(newdata$lat - newdata$tlat))

