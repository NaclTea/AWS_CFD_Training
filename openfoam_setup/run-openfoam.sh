#!/bin/bash
# Runs inside Singularity container
export PATH=/opt/slurm/bin:$PATH
source /usr/lib/openfoam/openfoam2312/etc/bashrc
cd /shared/cases/motorBikeTutorial
./Allrun