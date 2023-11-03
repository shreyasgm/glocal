#!/bin/bash
#SBATCH -c 15                # Number of cores
#SBATCH -t 0-08:00          # Runtime in D-HH:MM, minimum of 10 minutes
#SBATCH -p test          # Partition to submit to
#SBATCH --mem=180GB          # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH -o %x-%j.out    # File to which STDOUT will be written, %j inserts jobid
#SBATCH -e %x-%j.err     # File to which STDERR will be written, %j inserts jobid

module load 
R CMD BATCH --quiet --no-restore --no-save scriptfile outputfile