#!/bin/bash

# Create directory
mkdir /shared/cases
cd /shared/cases
# Download relevant files from github using sparse checkout
git clone --depth 1 --filter=blob:none --sparse https://github.com/OpenFOAM/OpenFOAM-10.git
cd OpenFOAM-10
git sparse-checkout set tutorials/incompressible/simpleFoam/motorBike
git checkout
cp -r tutorials/incompressible/simpleFoam/motorBike/ /shared/cases/motorBikeTutorial/

# Download geometry
wget https://raw.githubusercontent.com/OpenFOAM/OpenFOAM-10/master/tutorials/resources/geometry/motorBike.obj.gz \
    -P /shared/cases/motorBikeTutorial/constant/geometry/

# Clean up no longer needed files
rm -rf /shared/cases/OpenFOAM-10

# Edit decomposeParDict for our cluster
cat > /shared/cases/motorBikeTutorial/system/decomposeParDict << 'EOF'
/*--------------------------------*- C++ -*----------------------------------*\
  =========                 |
  \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox
   \\    /   O peration     |
    \\  /    A nd           |
     \\/     M anipulation  |
\*---------------------------------------------------------------------------*/
FoamFile
{
    format      ascii;
    class       dictionary;
    object      decomposeParDict;
}
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

numberOfSubdomains  128;

decomposer          scotch;

// ************************************************************************* //
EOF

# Edit Allrun for robustness
cat > /shared/cases/motorBikeTutorial/Allrun << 'EOF'
#!/bin/sh
cd ${0%/*} || exit 1    # Run from this directory

# Source tutorial run functions
. $WM_PROJECT_DIR/bin/tools/RunFunctions

# Geometry already present in constant/geometry/
runApplication surfaceFeatures
runApplication blockMesh
runApplication decomposePar -copyZero
runParallel snappyHexMesh -overwrite
runParallel patchSummary
runParallel potentialFoam
runParallel $(getApplication)
runApplication reconstructParMesh -constant
runApplication reconstructPar -latestTime
EOF
chmod +x /shared/cases/motorBikeTutorial/Allrun

echo "motorBike case setup and ready to run at /shared/cases/motorBikeTutorial"