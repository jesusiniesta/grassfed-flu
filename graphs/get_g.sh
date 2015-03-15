#/bin/bash
#set -x
set -e

PWD=`pwd`
BASE="${PWD%%proyecto*}"proyecto/

gcc "${BASE}/src/get_g.c" -o "${BASE}/get_g" -O3 -lm

echo `date`" to gawk 1"
gawk -f ${BASE}/src/select.s4.awk ${BASE}/data/geoNoOrigFFS.2013-08.dat ${BASE}/data/geoNoOrigFFS.2013-08.dat > ${BASE}/data/output.s4.unsorted

echo `date`" to gawk 2"
gawk -f ${BASE}/src/select.x4.awk ${BASE}/data/geoNoOrigFFS.2013-08.dat ${BASE}/data/geoNoOrigFFS.2013-08.dat > ${BASE}/data/output.x4.unsorted

echo `date`" to sort x4"
sort ${BASE}/data/output.x4.unsorted > ${BASE}/data/output.x4.sorted

echo `date`" to get_g 1"
$BASE/get_g 3600 0.5  `wc -l $BASE/data/output.x4.sorted` > ${BASE}/data/encounters.1h.500m.201308.el
echo `date`" to get_g 2"
$BASE/get_g 1800 0.5  `wc -l $BASE/data/output.x4.sorted` > ${BASE}/data/encounters.30m.500m.201308.el
echo `date`" to get_g 3"
$BASE/get_g 1800 0.25 `wc -l $BASE/data/output.x4.sorted` > ${BASE}/data/encounters.30m.250m.201308.el
echo `date`" to get_g 4"
$BASE/get_g 3600 1    `wc -l $BASE/data/output.x4.sorted` > ${BASE}/data/encounters.1h.1km.201308.el

echo `date`" all done"



./get_g 3600 0.5  `wc -l data/output.x4.sorted` > data/encounters.1h.500m.201308.el
./get_g 1800 0.5  `wc -l data/output.x4.sorted` > data/encounters.30m.500m.201308.el
./get_g 1800 0.25 `wc -l data/output.x4.sorted` > data/encounters.30m.250m.201308.el
./get_g 3600 1    `wc -l data/output.x4.sorted` > data/encounters.1h.1km.201308.el
