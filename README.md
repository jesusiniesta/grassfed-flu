# grassfed-flu

## todo

data/infection contains the id of each infected user, and the step. it could also include recoveries, but...

now go to rstudio and print a point for each one. you could copy moro's code to make a video too for bonus points.

## how-to


```bash

# filter the raw data
gawk -f grassfed-flu/munching/select.s4.awk data/geoNoOrigFFS.2013-08.dat data/geoNoOrigFFS.2013-08.dat > data/tweets4.2013-08.unsorted.da

# get the towns location, provincia and name
gawk -f grassfed-flu/munching/select.geonames.awk data/geonames/ES.txt > data/geonames/T2.csv

# assign each tweet to its closer town
gcc grassfed-flu/munching/get_towns_parallel.c -o get_towns_parallel -lm  -g -fopenmp 
date && ./get_towns_parallel `wc -l data/tweets.201308.unsorted.notown.dat` `wc -l data/geonames/T2.csv` > data/tweets.201308.unsorted.dat && date
sort data/tweets.201308.unsorted.dat > data/tweets.201308.dat

# find "encounters" 
gcc -o get_g grassfed-flu/graphs/get_g_2.c -Wall -lm -O3 -fopenmp
./get_g 3600 1     ./data/tweets.201308.dat data/encounters.1h.1km.201308.dat 
./get_g 3600 0.5   ./data/tweets.201308.dat data/encounters.1h.500m.201308.dat 
./get_g 1800 0.5   ./data/tweets.201308.dat data/encounters.30m.500m.201308.dat 
./get_g 3600 0.250 ./data/tweets.201308.dat data/encounters.1h.250m.201308.dat 
./get_g 1800 0.250 ./data/tweets.201308.dat data/encounters.30m.250m.201308.dat 

# extract the users from the tweets file
# (from io.R, R code)
setwd("~/proyecto")
source("grassfed-flu/lib.R")
tweets <- ReadTweets('data/tweets.201308.dat')
users  <- Users(tweets)
write.table(users, file="data/users.201308.dat", sep="|", quote=F, col.names=F)

# SEIR simulation
./grassfed-flu/simulation/sir.py --encountersfile data/encounters.30m.250m.201308.dat --usersfile data/users.201308.dat --print_infections > data/sir_infection.dat

```
