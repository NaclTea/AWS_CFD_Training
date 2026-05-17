#!/bin/bash

mkdir -p /shared/containers
cd /shared/containers

# ESI OpenFOAM v2312 runtime image - skip if already exists
if [ ! -f /shared/containers/openfoam-run_2312.sif ]; then
    singularity pull docker://opencfd/openfoam-run:2312
else
    echo "Container already exists, skipping pull"
fi
singularity exec /shared/containers/openfoam-run_2312.sif openfoam2312 -help

# CLONE OPENFOAM SCRIPTS FROM GITHUB
mkdir -p /shared/scripts
cd /shared/scripts
git clone --depth 1 --filter=blob:none --sparse https://github.com/NaclTea/AWS_CFD_Training.git
cd AWS_CFD_Training
git sparse-checkout set openfoam_setup
git checkout

# PREPARE CASE
bash /shared/scripts/AWS_CFD_Training/openfoam_setup/case-prep.sh

echo "OpenFOAM environment ready"