# grassfed-flu

## todo

data/infection contains the id of each infected user, and the step. it could also include recoveries, but...

now go to rstudio and print a point for each one. you could copy moro's code to make a video too for bonus points.

## how-to

filter the raw data

```bash
gawk -f grassfed-flu/munching/select.s4.awk data/geoNoOrigFFS.2013-08.dat data/geoNoOrigFFS.2013-08.dat > data/tweets4.2013-08.unsorted.dat
```

add the closest town to each tweet, then sort itt

```bash
gawk -f grassfed-flu/munching/select.geonames.awk data/geonames/ES.txt > data/geonames/T2.csv

gcc grassfed-flu/munching/get_towns_parallel.c -o get_towns_parallel -lm  -g -fopenmp 

date && ./get_towns_parallel `wc -l data/tweets4.201308.unsorted.dat` `wc -l data/geonames/T2.csv` > data/tweets5.201308.unsorted.dat && date

cat data/tweets5.201308.unsorted.dat | sort > data/tweets5.201308.dat
```

find "encounters" 

```bash
gcc -o get_g grassfed-flu/graphs/get_g.c -Wall -lm -O3
./get_g 3600 1 `wc -l ./data/tweets5.201308.dat`     | sort -k3 > data/encounters.1h.1km.201308.el 
./get_g 3600 0.5 `wc -l ./data/tweets5.201308.dat`   | sort -k3 > data/encounters.1h.500m.201308.el 
./get_g 1800 0.5 `wc -l ./data/tweets5.201308.dat`   | sort -k3 > data/encounters.30m.500m.201308.el 
./get_g 3600 0.250 `wc -l ./data/tweets5.201308.dat` | sort -k3 > data/encounters.1h.250m.201308.el 
./get_g 1800 0.250 `wc -l ./data/tweets5.201308.dat` | sort -k3 > data/encounters.30m.250m.201308.el 

```

extract the users

```{r}
# from io.R
setwd("~/proyecto")
source("grassfed-flu/lib.R")
tweets <- ReadTweets('data/tweets5.201308.dat')
users  <- Users(tweets)
write.table(users, file="data/users.201308.dat", sep="|", quote=F, col.names=F)
```

SEIR simulation

```bash
./grassfed-flu/simulation/sir.py --encountersfile data/encounters.30m.250m.201308.el --usersfile data/users.201308.dat --print_infections > data/sir_infection.dat
```
