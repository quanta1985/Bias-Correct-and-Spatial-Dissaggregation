#!/bin/bash

#SBATCH --job-name=pr.ACCESS-CM2
#SBATCH --time 240:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --partition=broadwell
#SBATCH --output=extract.ACCESS-CM2.pr.out

###sh tmp_run_bcsd.sh
cd /work/users/quanta/QUAN/GEMMES/preBCSD_CMIP6/ssp585_new/ACCESS-CM2/precipitation
mpirun ./runBCSD.sh
