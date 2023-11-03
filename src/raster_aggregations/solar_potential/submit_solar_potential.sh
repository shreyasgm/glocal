#!/bin/bash
#SBATCH -J solar_potential
#SBATCH -o logs/%x-%j.out
#SBATCH -e logs/%x-%j.err
#SBATCH -p serial_requeue
#SBATCH -t 0-08:00
#SBATCH -c 10
#SBATCH --mem=180GB
#SBATCH --mail-type=BEGIN,END,FAIL

singularity exec \
    --cleanenv \
    --env R_LIBS_USER=$HOME/R/ifxrstudio/RELEASE_3_15 \
    /n/singularity_images/informatics/ifxrstudio/ifxrstudio:RELEASE_3_15.sif Rscript process_solar_potential.R
