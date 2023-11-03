#!/bin/bash
DEST_FOLDER="/n/holystore01/LABS/hausmann_lab/lab/glocal_aggregations/shreyas/data/raw/rasters/wind_potential/"
cd $DEST_FOLDER
# This is the link to the data - https://globalwindatlas.info/api/gis/global/power-density/10
# However, the globalwindatlas.info website is incredibly slow
# wget https://globalwindatlas.info/api/gis/global/power-density/10

# Download using this link instead - https://datacatalog.worldbank.org/search/dataset/0038643
# Redirects to https://data.dtu.dk/articles/dataset/Global_Wind_Atlas_v3/9420803

