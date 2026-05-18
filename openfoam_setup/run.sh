#!/bin/bash
#SBATCH --job-name=motorBike
#SBATCH --nodes=8
#SBATCH --ntasks-per-node=16
#SBATCH --partition=compute
#SBATCH --output=/shared/cases/motorBikeTutorial/slurm-%j.log
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=juanphilipmarx+AWS_CFD@gmail.com

OF_SOURCE="source /usr/lib/openfoam/openfoam2312/etc/bashrc"

# Serial pre-processing inside container
singularity exec --bind /shared:/shared \
    /shared/containers/openfoam-run_2312.sif \
    bash -c "$OF_SOURCE && \
             cd /shared/cases/motorBikeTutorial && \
             surfaceFeatureExtract && \
             blockMesh && \
             decomposePar -copyZero"

# Parallel steps - use HOST mpirun, each rank runs inside container
mpirun -np 128 \
    singularity exec --bind /shared:/shared \
    /shared/containers/openfoam-run_2312.sif \
    bash -c "$OF_SOURCE && \
             cd /shared/cases/motorBikeTutorial && \
             snappyHexMesh -overwrite -parallel"

mpirun -np 128 \
    singularity exec --bind /shared:/shared \
    /shared/containers/openfoam-run_2312.sif \
    bash -c "$OF_SOURCE && \
             cd /shared/cases/motorBikeTutorial && \
             potentialFoam -parallel"

mpirun -np 128 \
    singularity exec --bind /shared:/shared \
    /shared/containers/openfoam-run_2312.sif \
    bash -c "$OF_SOURCE && \
             cd /shared/cases/motorBikeTutorial && \
             simpleFoam -parallel"

# Serial reconstruction
singularity exec --bind /shared:/shared \
    /shared/containers/openfoam-run_2312.sif \
    bash -c "$OF_SOURCE && \
             cd /shared/cases/motorBikeTutorial && \
             reconstructParMesh -constant && \
             reconstructPar -latestTime"