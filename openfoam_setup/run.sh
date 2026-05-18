#!/bin/bash
#SBATCH --job-name=motorBike
#SBATCH --nodes=8
#SBATCH --ntasks-per-node=16
#SBATCH --partition=compute
#SBATCH --output=/shared/cases/motorBikeTutorial/slurm-%j.log

# Create machinefile for mpirun
scontrol show hostnames $SLURM_JOB_NODELIST > /tmp/machinefile
HOSTS=$(scontrol show hostnames $SLURM_JOB_NODELIST | tr '\n' ',' | sed 's/,$//')

# Serial pre-processing
singularity exec --bind /shared:/shared \
    /shared/containers/openfoam-run_2312.sif \
    bash -c "source /usr/lib/openfoam/openfoam2312/etc/bashrc && \
             cd /shared/cases/motorBikeTutorial && \
             surfaceFeatures && blockMesh && decomposePar -copyZero"

# Parallel steps using container's own mpirun with explicit hosts
singularity exec --bind /shared:/shared \
    /shared/containers/openfoam-run_2312.sif \
    bash -c "source /usr/lib/openfoam/openfoam2312/etc/bashrc && \
             cd /shared/cases/motorBikeTutorial && \
             mpirun -np 128 -H ${HOSTS} snappyHexMesh -overwrite -parallel && \
             mpirun -np 128 -H ${HOSTS} potentialFoam -parallel && \
             mpirun -np 128 -H ${HOSTS} simpleFoam -parallel"

# Reconstruct
singularity exec --bind /shared:/shared \
    /shared/containers/openfoam-run_2312.sif \
    bash -c "source /usr/lib/openfoam/openfoam2312/etc/bashrc && \
             cd /shared/cases/motorBikeTutorial && \
             reconstructParMesh -constant && reconstructPar -latestTime"