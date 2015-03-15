 
 gcc grassfed-flu/get_towns.c -o get_towns -lm  -g
 gcc grassfed-flu/get_towns_parallel.c -o get_towns_parallel -lm  -g -fopenmp 
 
 
 date && ./get_towns `wc -l data/h.s4.201308.unsorted` `wc -l data/geonames/T2.csv` > example.serial && date
 
 date && ./get_towns_parallel `wc -l data/h.s4.201308.unsorted` `wc -l data/geonames/T2.csv` > example.parallel && date
 
 date && ./get_towns `wc -l data/h.s4.201308.unsorted` `wc -l data/geonames/T2.csv` > example.serial && date && ./get_towns_parallel `wc -l data/h.s4.201308.unsorted` `wc -l data/geonames/T2.csv` > example.parallel && date

gcc -o get_g grassfed-flu/get_g.c -Wall -lm -O3
date
./get_g 3600 1 `wc -l ./data/tweets5.201308.csv`     | sort -k3 > data/encounters.1h.1km.201308.el 
date
./get_g 3600 0.5 `wc -l ./data/tweets5.201308.csv`   | sort -k3 > data/encounters.1h.500m.201308.el 
date
exit
date && ./get_g 1800 0.5 `wc -l ./data/tweets5.201308.csv`   | sort -k3 > data/encounters.30m.500m.201308.el && date
date && ./get_g 3600 0.250 `wc -l ./data/tweets5.201308.csv` | sort -k3 > data/encounters.1h.250m.201308.el && date
date && ./get_g 1800 0.250 `wc -l ./data/tweets5.201308.csv` | sort -k3 > data/encounters.30m.250m.201308.el && date
