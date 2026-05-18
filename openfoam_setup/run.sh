#!/bin/bash
#SBATCH --job-name=motorBikeTutorial
#SBATCH --nodes=8
#SBATCH --ntasks-per-node=16
#SBATCH --partition=compute
#SBATCH --output=/shared/cases/motorBikeTutorial/slurm-%j.log

cd /shared/cases/motorBikeTutorial
singularity exec --bind /shared:/shared /shared/containers/openfoam-run_2312.sif bash -c "./Allrun"