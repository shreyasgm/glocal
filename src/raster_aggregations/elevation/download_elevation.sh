#!/bin/bash
# Download GTOPO30 elevation data from dropbox folder
DEST_FOLDER = "/n/holystore01/LABS/hausmann_lab/lab/glocal_aggregations/shreyas/data/raw/rasters/elevation"
DOWNLOAD_URL = "https://www.dropbox.com/sh/ua0849ejjh0qce7/AAA-CwGuNJb-_szU30dzid9Ua/GTOPO30?dl=1"
# Download to DEST_FOLDER
cd $DEST_FOLDER
wget -O GTOPO30.zip $DOWNLOAD_URL

# wget https://www.dropbox.com/sh/ua0849ejjh0qce7/AAA-CwGuNJb-_szU30dzid9Ua/GTOPO30?dl=1

# Unzip
unzip GTOPO30.zip