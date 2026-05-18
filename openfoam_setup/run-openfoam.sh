#!/bin/bash
# Runs inside Singularity container - sources OpenFOAM environment and runs case
source /usr/lib/openfoam/openfoam2312/etc/bashrc
cd /shared/cases/motorBikeTutorial
./Allrun