# shamelessly copied from oscar perpiñan https://github.com/oscarperpinan/spacetime-vis/blob/master/choropleth.R

install <- function() {
  install.packages('lattice')
  install.packages('ggplot2')
  install.packages('latticeExtra')
  install.packages('sp')
  install.packages('maptools')
}

library(lattice)
library(ggplot2)
library(latticeExtra)
library(sp)
library(maptools)

## Download boundaries information 

old <- setwd(tempdir())
download.file('http://goo.gl/TIvr4', 'mapas_completo_municipal.rar')
system2('unrar', c('e', 'mapas_completo_municipal.rar'))
espMap <- readShapePoly(fn="esp_muni_0109")
Encoding(levels(espMap$NOMBRE)) <- "latin1"

provinces <- readShapePoly(fn="spain_provinces_ag_2")
setwd(old)

## dissolve repeated polygons
espPols <- unionSpatialPolygons(espMap, espMap$PROVMUN) 

espMapVotes <- SpatialPolygonsDataFrame(espPols)

spplot(espPols)
