#!/bin/bash
#SBATCH --job-name=motorBike
#SBATCH --nodes=8
#SBATCH --ntasks-per-node=16
#SBATCH --partition=compute
#SBATCH --output=/shared/cases/motorBikeTutorial/slurm-%j.log

# Get hostlist from SLURM
HOSTS=$(scontrol show hostnames $SLURM_JOB_NODELIST | tr '\n' ',' | sed 's/,$//')

# Set OpenFOAM source command
OF_SOURCE="source /usr/lib/openfoam/openfoam2312/etc/bashrc"

# Serial pre-processing
singularity exec --bind /shared:/shared \
    /shared/containers/openfoam-run_2312.sif \
    bash --login -c "$OF_SOURCE && \
                     cd /shared/cases/motorBikeTutorial && \
                     surfaceFeatures && \
                     blockMesh && \
                     decomposePar -copyZero"

# Parallel steps - force SSH transport, bypass SLURM launcher
singularity exec --bind /shared:/shared \
    /shared/containers/openfoam-run_2312.sif \
    bash --login -c "$OF_SOURCE && \
                     cd /shared/cases/motorBikeTutorial && \
                     mpirun --mca plm_rsh_agent ssh \
                            --mca btl_tcp_if_include eth0 \
                            -np 128 -H ${HOSTS} \
                            snappyHexMesh -overwrite -parallel && \
                     mpirun --mca plm_rsh_agent ssh \
                            --mca btl_tcp_if_include eth0 \
                            -np 128 -H ${HOSTS} \
                            potentialFoam -parallel && \
                     mpirun --mca plm_rsh_agent ssh \
                            --mca btl_tcp_if_include eth0 \
                            -np 128 -H ${HOSTS} \
                            simpleFoam -parallel"

# Reconstruct
singularity exec --bind /shared:/shared \
    /shared/containers/openfoam-run_2312.sif \
    bash --login -c "$OF_SOURCE && \
                     cd /shared/cases/motorBikeTutorial && \
                     reconstructParMesh -constant && \
                     reconstructPar -latestTime"