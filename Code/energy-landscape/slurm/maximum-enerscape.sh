#!/bin/bash

#SBATCH -J EnerscapeMaximum
#SBATCH -D /work/berti
#SBATCH -o /work/berti/climatescape/%x.log
#SBATCH -e /work/berti/climatescape/%x.err
#SBATCH --mem-per-cpu=12G
#SBATCH -t 0-00:20:00

array_or_job_id=${SLURM_ARRAY_JOB_ID:-$SLURM_JOB_ID}

module load Conda/24.11.2
source activate climatescape
source /home/berti/climate-energy/slurm/load-modules

array_or_job_id=${SLURM_ARRAY_JOB_ID:-$SLURM_JOB_ID}

datadir=$1
mass=$2

Rscript --vanilla /home/berti/climate-energy/scripts/maximum-enerscape.R $datadir $mass
