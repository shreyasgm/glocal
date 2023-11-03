#!/bin/bash

# Set subfolders list
subfolders=(dmsp elevation fao population precipitation temperature viirs ruggedness)

# Loop through subfolders
# cd into subfolder
# submit job
for subfolder in "${subfolders[@]}"; do
    cd $subfolder
    sbatch submit_$subfolder.sh
    cd ..
done
