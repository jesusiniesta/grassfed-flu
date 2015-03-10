library(sp)
library(rgeos)

# https://stackoverflow.com/questions/21977720/r-finding-closest-neighboring-point-and-number-of-neighbors-within-a-given-rad/21981693#21981693

htweets <- head(tweets, n=size);
mydata <- select(htweets, lat, lon, user.name, msg)

sp.mydata <- mydata
coordinates(sp.mydata) <- ~lon+lat

towns$lon <- towns$longitude
towns$lat <- towns$latitude
sp.towns <- towns
coordinates(sp.towns) <- ~longitude+latitude

# Now calculate pairwise distances between points
d <- gDistance(spgeom2=sp.mydata, spgeom1=sp.towns, byid=T)

# Find second shortest distance (closest distance is of point to itself, therefore use second shortest)
min.d <- apply(d, 1, function(x) order(x, decreasing=F)[1])

# Construct new data frame with desired variables
newdata <- cbind(mydata, towns[min.d,c("geonameid", "provincia", "asciiname", "population", "lon", "lat")])

#colnames(newdata) <- c(colnames(mydata), "n.lat", "n.lon", "n.user.name", "n.msg", 'distance')

