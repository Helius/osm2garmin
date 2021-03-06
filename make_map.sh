#!/bin/bash

HL="[33m"
CL="[0m"

usage() {
	  echo $HL"Usage: $0 [ update_all | rebuild_map | test_style ]"
		echo "    update_all  - download new data and rebuild all"
		echo "    rebuild_map - rebuild only nsk map with exist contours"
		echo "    test_style  - like 'rebuild_map' but for small region (it's faster!)"
		  exit
}

if [ $# -ne 1 ]; then
	  usage
fi



REGION_OSM="nsk.osm"        # name of main.map
RECT="81.8,54.1,84.5,55.5"  # rect for main map region obtained from big map
RECT_TEST="83.1,54.85,84,55.5" # the same, but small 



if [ "$1" == "update_all" ]; then
	echo $HL"========== update all ============="$CL

	# get contour line and make OSM file, if not exist
	if [ -f no.srtm.osm ]; then
		echo $HL"srtm.osm exist:         ok"$CL
	else
		echo $HL"========== make srt.osm file ============="$CL
		mono Srtm2Osm/Srtm2Osm.exe -bounds3 "http://www.openstreetmap.org/?lat=54.758&lon=83.102&zoom=9&layers=M" -cat 250 50 -step 10 -o no.srtm.osm
	fi

	# make garmin *.img from OSM contour map
	java -Xmx2000M -jar mkgmap/mkgmap.jar --mapname=74010000 --style-file=cyclemap --transparent no.srtm.osm

	# rm old data
	rm RU-NVS.osm.bz2
	rm RU-NVS.osm
	# download new map
	wget http://data.gis-lab.info/osm_dump/dump/latest/RU-NVS.osm.bz2
	# unzip osm data
	bunzip2 -d RU-NVS.osm.bz2
	# get nsk region from big nso map
	./osmconvert32 RU-NVS.osm -b=$RECT >$REGION_OSM

elif [ "$1" == "test_style" ]; then

echo $HL"========== test style ============="$CL
	if [ -f RU-NVS.osm ]; then
		echo $HL"osm data exist:             ok"$CL
	else
		echo $HL"osm data exist:             no"$CL
		if [ -f RU-NVS.osm.bz2 ]; then
			echo $HL"bz2 archive of osm data exist: ok"$CL
		else
			echo $HL"bz2 archive of osm data exist: no"$CL
			echo $HL"downloading..."$CL
			wget http://data.gis-lab.info/osm_dump/dump/latest/RU-NVS.osm.bz2
		fi
		bunzip2 -d RU-NVS.osm.bz2
	fi
	#check that nsk.osm not exist or has big size, then recreate it
	if [[ ! -f $REGION_OSM  ]] || [[ "`stat -c%s $REGION_OSM`" -gt "1000000" ]] ; then
		echo $HL"get small test region"$CL
		./osmconvert32 RU-NVS.osm -b=$RECT_TEST > $REGION_OSM
	fi
elif [ "$1" == "rebuild_map" ]; then
	echo $HL"========== rebuild map  ============="$CL
	#check that nsk.osm not exist or has small size, then recreate it
	if [[ ! -f "$REGION_OSM"  ]] || [[ `stat -c%s $REGION_OSM` -lt "1000000" ]] ; then
		echo $HL"get nsk map region from big map"$CL
	./osmconvert32 RU-NVS.osm -b=$RECT > $REGION_OSM
	fi
else
	usage
	exit
fi

# make garmin *.img from main maps 
#java -Xmx1000M -jar mkgmap/mkgmap.jar --style-file=openmtbmap --mapname=74000000 --transparent --generate-sea=polygons,extend-sea-sectors,close-gaps=6000 --reduce-point-density=5.4 --x-reduce-point-density-polygon=5.4 --index --adjust-turn-headings --ignore-maxspeeds --ignore-turn-restrictions --remove-short-arcs=4 --description=openmtbmap_ru --location-autofill=1 --route --country-abbr=ru RU-NVS.osm
#java -Xmx2000M -jar mkgmap/mkgmap.jar --code-page=1251 --style-file=cyclemap --mapname=74000000 --transparent RU-NVS.osm
echo $HL"========== make main map  ============="$CL
java -Xmx2000M -jar mkgmap/mkgmap.jar --code-page=1251 --style-file=cyclemap --mapname=74000000 --transparent $REGION_OSM
# merge main maps and conoturs (order of arguments important!!, first maps, second contours) to gmapsupp.img garmin map
echo $HL"========== merge map to gmapsupp  ============="$CL
java -Xmx1000M -jar mkgmap/mkgmap.jar --gmapsupp 74000000.img 74010000.img
# rm main map img
#rm 74000000.img

#calc md5 summ for result map
md5sum gmapsupp.img
DAY=`date +"%d-%m-%Y"`
SUF=""
 
if [ "$1" == "test_style" ]; then
	SUF="-small"
elif [ "$1" == "rebuild_map" ]; then
	SUF="-reb"
fi

cp gmapsupp.img /data/dropbox/gps/maps/$DAY-gmapsupp$SUF.img
