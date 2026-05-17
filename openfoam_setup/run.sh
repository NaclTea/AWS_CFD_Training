#!/bin/bash
# SLURM job script for running OpenFOAM motorBike case on 8x c5n.4xlarge nodes

#SBATCH --job-name=motorBike
#SBATCH --nodes=8
#SBATCH --ntasks-per-node=16
#SBATCH --partition=compute
#SBATCH --output=/shared/cases/motorBikeTutorial/slurm-%j.log

cd /shared/cases/motorBikeTutorial
singularity exec --mpi=pmi2 /shared/containers/openfoam-run_2312.sif bash -c "./Allrun"