#!/bin/bash

HL="[33m"
CL="[0m"

REGION_OSM="nsk.map" #name of map
RECT="81.8,54.1,84.5,55.5"  # rect for main map region obtained from big map
SRTM_RECT_URL="http://www.openstreetmap.org/?lat=54.758&lon=83.102&zoom=9&layers=M"


#internal vars
SRTMIMG_NAME="74010000"
MAPIMG_MANE="74000000"


usage() {
	  echo $HL"Usage: $0 [ update_map ]"
}

prepare_srtm () {
	if [ -f no.srtm.osm ]; then
		echo $HL"srtm.osm exist:         ok"$CL
	else
		echo $HL"make srt.osm file..."$CL
		mono Srtm2Osm/Srtm2Osm.exe -bounds3 SRTM_RECT_URL -cat 250 50 -step 10 -o no.srtm.osm
	fi
}

prepare_map () {
# rm old data
rm -rf RU-NVS.osm.bz2
rm -rf RU-NVS.osm
echo $HL"downloading RU-NVS.osm ..."$CL
wget http://data.gis-lab.info/osm_dump/dump/latest/RU-NVS.osm.bz2
echo $HL"unpack big map..."$CL
bunzip2 -d RU-NVS.osm.bz2
echo $HL"get nsk map region from big map..."$CL
./osmconvert32 RU-NVS.osm -b=$RECT > $REGION_OSM
}

build_srtm () {
	if [ -f $SRTMIMG_NAME.img ]; then
	# make garmin *.img from OSM contour map
	java -Xmx2000M -jar mkgmap/mkgmap.jar --mapname=$SRTMIMG_NAME --style-file=cyclemap --transparent no.srtm.osm
	fi
}

build_map () {
echo $HL"make main map..."$CL
java -Xmx2000M -jar mkgmap/mkgmap.jar --code-page=1251 --style-file=cyclemap --mapname=$MAPIMG_MANE --transparent $REGION_OSM
}

make_img () {
echo $HL"merge map to gmapsupp..."$CL
java -Xmx1000M -jar mkgmap/mkgmap.jar --gmapsupp $MAPIMG_MANE.img $SRTMIMG_NAME.img
DAY=`date +"%d-%m-%Y"`
SUF="daily"
cp gmapsupp.img /data/dropbox/gps/maps/$SUF.img
}

case "$1" in
"update_map" )
echo "======== update_map =========="
prepare_srtm
prepare_map
build_srtm
build_map
make_img
;;
*)
usage
exit 1
;;
esac
