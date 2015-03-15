# grassfed-flu

```bash
gawk -f grassfed-flu/munching/select.s4.awk data/geoNoOrigFFS.2013-08.dat data/geoNoOrigFFS.2013-08.dat > data/tweets4.2013-08.unsorted.dat

gawk -f grassfed-flu/munching/select.geonames.awk data/geonames/ES.txt > data/geonames/T2.csv

gcc grassfed-flu/munching/get_towns_parallel.c -o get_towns_parallel -lm  -g -fopenmp 

date && ./get_towns_parallel `wc -l data/tweets4.201308.unsorted.dat` `wc -l data/geonames/T2.csv` > data/tweets5.2013-08.unsorted.dat && date

cat data/tweets5.2013-08.unsorted.dat | sort > data/tweets5.2013-08.dat
```
