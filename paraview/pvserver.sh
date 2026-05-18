#!/bin/bash
#SBATCH --job-name=pvserver
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=16
#SBATCH --partition=compute
#SBATCH --output=/shared/paraview-server.log
#SBATCH --time=01:00:00

mpirun -np 32 /shared/paraview/bin/pvserver \
    --mpi \
    --server-port=11111 \
    --timeout=3600 \
    --force-offscreen-rendering