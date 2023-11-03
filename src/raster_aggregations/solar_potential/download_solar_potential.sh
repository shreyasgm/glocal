#!/bin/bash
DEST_FOLDER="/n/holystore01/LABS/hausmann_lab/lab/glocal_aggregations/shreyas/data/raw/rasters/solar_potential/"
cd $DEST_FOLDER
# wget with name
wget -O "World_PVOUT_GISdata_LTAy_AvgDailyTotals_GlobalSolarAtlas-v2_GEOTIFF.zip" "https://solargis.com/file?url=download/World/World_PVOUT_GISdata_LTAy_AvgDailyTotals_GlobalSolarAtlas-v2_GEOTIFF.zip&bucket=globalsolaratlas.info"
# Unzip
unzip World_PVOUT_GISdata_LTAy_AvgDailyTotals_GlobalSolarAtlas-v2_GEOTIFF.zip