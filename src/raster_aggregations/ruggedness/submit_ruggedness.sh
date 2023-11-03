#!/bin/bash
#SBATCH -J ruggedness
#SBATCH -o slurm_logfile.out
#SBATCH -e slurm_logfile.err
#SBATCH -p serial_requeue
#SBATCH -t 0-08:00
#SBATCH -c 10
#SBATCH --mem=180GB
#SBATCH --mail-type=BEGIN,END,FAIL

singularity exec \
    --cleanenv \
    --env R_LIBS_USER=$HOME/R/ifxrstudio/RELEASE_3_15 \
    /n/singularity_images/informatics/ifxrstudio/ifxrstudio:RELEASE_3_15.sif Rscript process_ruggedness.R
