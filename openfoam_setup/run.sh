#!/bin/bash
#SBATCH --job-name=motorBike
#SBATCH --nodes=8
#SBATCH --ntasks-per-node=16
#SBATCH --partition=compute
#SBATCH --output=/shared/cases/motorBikeTutorial/slurm-%j.log

singularity exec \
    --bind /shared:/shared \
    /shared/containers/openfoam-run_2312.sif \
    bash /shared/scripts/AWS_CFD_Training/openfoam_setup/run-openfoam.sh