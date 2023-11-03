#!/bin/bash
#SBATCH -J download_wind
#SBATCH -o logs/%x-%j.out
#SBATCH -e logs/%x-%j.err
#SBATCH -p test
#SBATCH -t 0-08:00
#SBATCH -c 10
#SBATCH --mem=50GB
#SBATCH --mail-type=BEGIN,END,FAIL

source activate cid
python download_wind_potential.py