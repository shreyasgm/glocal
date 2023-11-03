#!/bin/bash
DEST_FOLDER="/n/holystore01/LABS/hausmann_lab/lab/glocal_aggregations/shreyas/data/raw/rasters/precipitation/cru"
cd $DEST_FOLDER
wget https://crudata.uea.ac.uk/cru/data/hrg/cru_ts_4.06/cruts.2205201912.v4.06/pre/cru_ts4.06.1901.2021.pre.dat.nc.gz
# Unzip
gunzip cru_ts4.06.1901.2021.pre.dat.nc.gz