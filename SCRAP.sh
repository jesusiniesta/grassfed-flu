
gcc grassfed-flu/get_towns.c -o get_towns -lm  -g
gcc grassfed-flu/get_towns_parallel.c -o get_towns_parallel -lm  -g -fopenmp 


date && ./get_towns `wc -l data/h.s4.201308.unsorted` `wc -l data/geonames/T2.csv` > example.serial && date

date && ./get_towns_parallel `wc -l data/h.s4.201308.unsorted` `wc -l data/geonames/T2.csv` > example.parallel && date

date && ./get_towns `wc -l data/h.s4.201308.unsorted` `wc -l data/geonames/T2.csv` > example.serial && date && ./get_towns_parallel `wc -l data/h.s4.201308.unsorted` `wc -l data/geonames/T2.csv` > example.parallel && date
