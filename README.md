# AWS HPC OpenFOAM Cluster

A reproducible AWS ParallelCluster setup for running OpenFOAM CFD simulations 
on a SLURM-managed HPC cluster, with parallel ParaView post-processing.

## Stack
- AWS ParallelCluster 3.x
- SLURM scheduler
- OpenFOAM v2312 (ESI) via Singularity
- ParaView 5.11 parallel server
- 8x c5n.4xlarge compute nodes (128 cores total)

## Phases
- `cluster/` — cluster configuration and deployment
- `openfoam/` — case setup and job submission
- `postprocess/` — parallel ParaView server setup
- `teardown/` — clean cluster deletion

## Usage
See each directory for scripts and
