#!/bin/bash

RECT="81.8,54.1,84.5,55.5"

# get contour line and make OSM file
mono Srtm2Osm/Srtm2Osm.exe -bounds3 "http://www.openstreetmap.org/?lat=54.758&lon=83.102&zoom=9&layers=M" -cat 250 50 -step 10 -o no.srtm.osm

# make garmin *.img from OSM contour map
java -Xmx2000M -jar mkgmap/mkgmap.jar --mapname=74010000 --transparent no.srtm.osm

# get nsk region from big nso map
./osmconvert32 RU-NVS.osm -b=$RECT >nsk.osm

# make garmin *.img from main maps 
#java -Xmx1000M -jar mkgmap/mkgmap.jar --style-file=openmtbmap --mapname=74000000 --transparent --generate-sea=polygons,extend-sea-sectors,close-gaps=6000 --reduce-point-density=5.4 --x-reduce-point-density-polygon=5.4 --index --adjust-turn-headings --ignore-maxspeeds --ignore-turn-restrictions --remove-short-arcs=4 --description=openmtbmap_ru --location-autofill=1 --route --country-abbr=ru RU-NVS.osm
#java -Xmx2000M -jar mkgmap/mkgmap.jar --code-page=1251 --style-file=cyclemap --mapname=74000000 --transparent RU-NVS.osm
java -Xmx2000M -jar mkgmap/mkgmap.jar --code-page=1251 --style-file=cyclemap --mapname=74000000 --transparent nsk.osm

# merge main maps and conoturs (order of arguments important!!, first maps, second contours) to gmapsupp.img garmin map
java -Xmx1000M -jar mkgmap/mkgmap.jar --gmapsupp 74000000.img 74010000.img

#calc md5 summ for result map
md5sum gmapsupp.img
