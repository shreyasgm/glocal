#!/bin/bash
#SBATCH -J download_viirs
#SBATCH -o logfiles/%x-%j.out
#SBATCH -e logfiles/%x-%j.err
#SBATCH -p test
#SBATCH -t 0-08:00
#SBATCH -c 15
#SBATCH --mem=180GB
#SBATCH --mail-type=BEGIN,END,FAIL

export PROJ_DIR="/n/holystore01/LABS/hausmann_lab/lab/glocal_aggregations/shreyas/proj/2023-02-05 - Pipeline/download_raster/viirs"

source activate cid
cd $PROJ_DIR
EOG_PASSWORD="MR%0k&4pS@rm" python download_viirs.py
