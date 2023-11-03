#!/bin/bash

#SBATCH --job-name=ogr_sjoin
#SBATCH --partition=serial_requeue
#SBATCH --time=03-00:00:00
#SBATCH --mem=450G
#SBATCH --cpus-per-task=10
#SBATCH --output=logs/ogr_sjoin_%j.out
#SBATCH --error=logs/ogr_sjoin_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL

source activate cid
echo $CONDA_DEFAULT_ENV

# Define variables
VRT_FILE="./grip.vrt"
OUTPUT_FILE="/n/home10/shreyasgm/ln_hausmann_lab/glocal_aggregations/shreyas/data/intermediate/roads/grip/grip_roads_with_admin_boundaries_level_1.csv"

# # Define Mollweide WKT
# MOLLWEIDE_WKT="PROJCS[\"World_Mollweide\",GEOGCS[\"GCS_WGS_1984\",DATUM[\"D_WGS_1984\",SPHEROID[\"WGS_1984\",6378137,298.257223563]],PRIMEM[\"Greenwich\",0],UNIT[\"Degree\",0.017453292519943295]],PROJECTION[\"Mollweide\"],PARAMETER[\"False_Easting\",0],PARAMETER[\"False_Northing\",0],PARAMETER[\"Central_Meridian\",0],UNIT[\"Meter\",1]]"

SQL_COMMAND="SELECT A.GID_1, B.GP_RTP, ST_Length(ST_Transform(B.Shape, 'ESRI:54009')) as Length FROM gadm36_1 AS A, GRIP4_GlobalRoads AS B WHERE ST_Within(B.Shape, A.geometry)"
# SQL_COMMAND="SELECT A.GID_1, B.GP_RTP, B.Shape_Length as Length FROM gadm36_1 AS A, GRIP4_GlobalRoads AS B WHERE ST_Within(B.geometry, A.geometry)"
# SQL_COMMAND="SELECT A.GID_1, B.GP_RTP, ST_Length(ST_Transform(B.Shape, '$MOLLWEIDE_WKT')) as Length FROM gadm36_1 AS A, GRIP4_GlobalRoads AS B WHERE ST_Within(B.Shape, A.geometry)"

# Time the ogr2ogr command
start_time=$(date +%s)

# Use ogr2ogr with SQL to get the intersection and show progress
ogr2ogr -f "CSV" -sql "$SQL_COMMAND" -dialect SQLITE -progress $OUTPUT_FILE $VRT_FILE

end_time=$(date +%s)

# Calculate the time difference and print it
duration=$((end_time - start_time))
echo "The ogr2ogr command took $duration seconds."
