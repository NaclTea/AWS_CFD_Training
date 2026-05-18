#!/bin/bash
# case-prep.sh
# Downloads and configures motorBike tutorial for 128 core MPI run on ESI OpenFOAM v2312

set -e

# ─── SETUP DIRECTORIES ────────────────────────────────────────────────────────
mkdir -p /shared/cases
cd /shared/cases

# ─── DOWNLOAD MOTORBIKE TUTORIAL ──────────────────────────────────────────────
git clone --depth 1 --filter=blob:none --sparse https://github.com/OpenFOAM/OpenFOAM-10.git
cd OpenFOAM-10
git sparse-checkout set tutorials/incompressible/simpleFoam/motorBike
git checkout
cd /shared/cases
cp -r OpenFOAM-10/tutorials/incompressible/simpleFoam/motorBike /shared/cases/motorBikeTutorial
rm -rf /shared/cases/OpenFOAM-10

# ─── DOWNLOAD AND PREPARE GEOMETRY ───────────────────────────────────────────
mkdir -p /shared/cases/motorBikeTutorial/constant/triSurface
wget https://raw.githubusercontent.com/OpenFOAM/OpenFOAM-10/master/tutorials/resources/geometry/motorBike.obj.gz \
    -P /shared/cases/motorBikeTutorial/constant/triSurface/
gunzip -d /shared/cases/motorBikeTutorial/constant/triSurface/motorBike.obj.gz

# ─── COPY .orig FILES TO PROPER NAMES ────────────────────────────────────────
for f in /shared/cases/motorBikeTutorial/0/*.orig; do
    cp "$f" "${f%.orig}"
done

# ─── DECOMPOSITION ───────────────────────────────────────────────────────────
cat > /shared/cases/motorBikeTutorial/system/decomposeParDict << 'EOF'
FoamFile
{
    format      ascii;
    class       dictionary;
    object      decomposeParDict;
}
numberOfSubdomains  128;
method          scotch;
EOF

# ─── surfaceFeatureExtractDict (ESI v2312 format) ─────────────────────────────
cat > /shared/cases/motorBikeTutorial/system/surfaceFeatureExtractDict << 'EOF'
FoamFile
{
    version     2.0;
    format      ascii;
    class       dictionary;
    object      surfaceFeatureExtractDict;
}
motorBike.obj
{
    extractionMethod    extractFromSurface;
    includedAngle       150;
    geometricTestOnly   yes;
    intersectionMethod  none;
    writeObj            yes;
}
EOF

# ─── meshQualityDict (copy from container + overrides) ───────────────────────
singularity exec /shared/containers/openfoam-run_2312.sif \
    bash -c "cat /usr/lib/openfoam/openfoam2312/etc/caseDicts/meshQualityDict" > \
    /shared/cases/motorBikeTutorial/system/meshQualityDict
echo "minFaceWeight 0.02;" >> /shared/cases/motorBikeTutorial/system/meshQualityDict
echo "errorReduction 0.75;" >> /shared/cases/motorBikeTutorial/system/meshQualityDict
echo "nSmoothScale 4;" >> /shared/cases/motorBikeTutorial/system/meshQualityDict

# ─── snappyHexMeshDict fixes ─────────────────────────────────────────────────
# Fix refinement level syntax (Foundation v10 -> ESI v2312)
sed -i 's/            level   4;/            levels  ((4 4));/' \
    /shared/cases/motorBikeTutorial/system/snappyHexMeshDict
# Fix meshQualityDict include path
sed -i 's|caseDicts/mesh/generation/meshQualityDict|caseDicts/meshQualityDict|' \
    /shared/cases/motorBikeTutorial/system/snappyHexMeshDict
# Add locationInMesh
sed -i '/refinementRegions/i\    locationInMesh (3 0 1);' \
    /shared/cases/motorBikeTutorial/system/snappyHexMeshDict
# Disable addLayers
sed -i 's/addLayers       true/addLayers       false/' \
    /shared/cases/motorBikeTutorial/system/snappyHexMeshDict

# ─── transportProperties (ESI v2312 format) ──────────────────────────────────
cat > /shared/cases/motorBikeTutorial/constant/transportProperties << 'EOF'
FoamFile
{
    version     2.0;
    format      ascii;
    class       dictionary;
    object      transportProperties;
}
transportModel  Newtonian;
nu              [0 2 -1 0 0 0 0] 1.5e-05;
EOF

# ─── turbulenceProperties (ESI v2312 format) ─────────────────────────────────
cat > /shared/cases/motorBikeTutorial/constant/turbulenceProperties << 'EOF'
FoamFile
{
    version     2.0;
    format      ascii;
    class       dictionary;
    object      turbulenceProperties;
}
simulationType  RAS;
RAS
{
    RASModel        kOmegaSST;
    turbulence      on;
    printCoeffs     on;
}
EOF

# ─── cuttingPlane (ESI v2312 format) ─────────────────────────────────────────
cat > /shared/cases/motorBikeTutorial/system/cuttingPlane << 'EOF'
cuttingPlane
{
    type            surfaces;
    libs            ("libsampling.so");
    writeControl    writeTime;
    surfaceFormat   vtk;
    fields          (p U);
    interpolationScheme cellPoint;
    surfaces
    {
        yNormal
        {
            type            cuttingPlane;
            planeType       pointAndNormal;
            pointAndNormalDict
            {
                point   (0 0 0);
                normal  (0 1 0);
            }
            interpolate     true;
        }
    }
}
EOF

# ─── controlDict (remove Foundation v10 function includes) ───────────────────
cat > /shared/cases/motorBikeTutorial/system/controlDict << 'EOF'
FoamFile
{
    format      ascii;
    class       dictionary;
    object      controlDict;
}
application     simpleFoam;
startFrom       startTime;
startTime       0;
stopAt          endTime;
endTime         500;
deltaT          1;
writeControl    timeStep;
writeInterval   100;
purgeWrite      0;
writeFormat     binary;
writePrecision  6;
writeCompression off;
timeFormat      general;
timePrecision   6;
runTimeModifiable true;
functions
{
    #include "streamlines"
    #include "cuttingPlane"
    #include "forceCoeffs"
}
EOF

echo "motorBikeTutorial case ready at /shared/cases/motorBikeTutorial"