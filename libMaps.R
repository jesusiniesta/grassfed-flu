library(sp)
library(rgeos)
library(dplyr)

# https://stackoverflow.com/questions/21977720/r-finding-closest-neighboring-point-and-number-of-neighbors-within-a-given-rad/21981693#21981693

size <- (dim(tweets)[1]/2.0)+2;
htweets <- head(tweets, n=size);
mydata <- select(htweets, lat, lon, user.name);

sp.mydata <- mydata
coordinates(sp.mydata) <- ~lon+lat

towns$lon <- towns$longitude
towns$lat <- towns$latitude
sp.towns <- towns[1:dim(towns)[1],]
coordinates(sp.towns) <- ~longitude+latitude

t0 <- proc.time(); 
times <- c(t0[[3]])

# Now calculate pairwise distances between points
d <- gDistance(spgeom2=sp.mydata, spgeom1=sp.towns, byid=T)

times <- c(times, proc.time()[[3]])

# Find second shortest distance (closest distance is of point to itself, therefore use second shortest)
min.d <- apply(d, 1, function(x) order(x, decreasing=F)[1])

times <- c(times, proc.time()[[3]])

# Construct new data frame with desired variables
newdata <- cbind(mydata, towns[min.d,c("geonameid", "provincia", "asciiname", "population", "lon", "lat")])
names(newdata) <- c("lat", "lon", "user.name", "geonameid", "provincia", "asciiname", "population", "tlon", "tlat")

times <- c(times, proc.time()[[3]])

#colnames(newdata) <- c(colnames(mydata), "n.lat", "n.lon", "n.user.name", "n.msg", 'distance')

benchmark <- PrintTime("libMaps", t0);
expected.total.time <- (dim(tweets)[1]*benchmark)/size
printf("for the whole dataset it'll take: %f hours\n", (expected.total.time/(60^2)));
 
times <- c(times, proc.time()[[3]])

#newdata[which(abs(newdata$lat - newdata$tlat)>3),]
max(abs(newdata$lat - newdata$tlat))

times <- c(times, proc.time()[[3]])


