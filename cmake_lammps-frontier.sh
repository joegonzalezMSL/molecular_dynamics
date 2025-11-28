#!/bin/bash
# ----------------------------------------------------------------------
# cmake_lammps_frontier.sh v 0.1, joe gonzalez, 11.24.2025
# CMake build script for LAMMPS with Kokkos HIP on Frontier
# Supports "latest" (clone fresh repo) or "cmake" (use existing)
# ----------------------------------------------------------------------

## load Frontier modules
load_modules() {
    echo ">>> Loading Frontier modules..."
    module purge
    module load craype-x86-trento
    module load craype-accel-amd-gfx90a
    module load PrgEnv-amd
    module load rocm/6.2.4
}


##find most recent LAMMPS directory
find_recent_lammps_build() {
    local newest
    newest=$(\ls -dt lammps-* 2>/dev/null | head -n1 || true)
    echo "$newest"
}


##timestamp helper
timestamp() {
    date +"%m%d%Y_%H%M%S"
}

## get the command line args
if [ $# -ne 1 ]; then
    echo "ERROR: Missing argument!"
    echo "USAGE: $0 {latest | cmake}"
    exit 1
fi

MODE="$1"

##build in "latest" mode: clone fresh repo
if [ "$MODE" = "latest" ]; then
    echo ">>> Mode: get latest"

    NEWSTAMP=$(date +"%Y%m%d")
    NEWDIR="lammps-${NEWSTAMP}"
    BACKUPSTAMP=$(timestamp)

    ## backup existing lammps-* directories
    EXISTING=$(ls -d lammps-* 2>/dev/null || true)
    if [ -n "$EXISTING" ]; then
        for d in $EXISTING; do
            echo ">>> Backup existing: $d -> ${d}_backup_${BACKUPSTAMP}"
            mv "$d" "${d}_backup_${BACKUPSTAMP}"
        done
    fi

    echo ">>> Cloning fresh LAMMPS into: $NEWDIR"
    git clone https://github.com/lammps/lammps.git "$NEWDIR"
    cd "$NEWDIR"
    load_modules

    BUILDDIR="build"
    echo ">>> Creating build directory: $BUILDDIR"
    rm -rf "$BUILDDIR"
    mkdir "$BUILDDIR"
    cd "$BUILDDIR"
fi


## build in "cmake" mode: use existing LAMMPS, create new build dir
if [ "$MODE" = "cmake" ]; then
    echo ">>> Mode: cmake in existing directory"
    NEWEST_DIR=$(find_recent_lammps_build)
    if [ -z "$NEWEST_DIR" ]; then
        echo "ERROR: No LAMMPS directories found (expected lammps-*)"
        exit 1
    fi
    cd "$NEWEST_DIR"
    load_modules

    BUILDSTAMP=$(timestamp)
    BUILDDIR="build_${BUILDSTAMP}"
    echo ">>> Creating build directory: $BUILDDIR"
    mkdir "$BUILDDIR"
    cd "$BUILDDIR"

fi


echo ">>> Running CMake configuration..."
echo "-D LAMMPS_BIGBIG:BOOL=ON \\
  -D LAMMPS_SMALLBIG:BOOL=OFF \\
  -D LAMMPS_SMALLSMALL:BOOL=OFF \\
  -D CMAKE_C_COMPILER=cc \\
  -D CMAKE_CXX_COMPILER=CC \\
  -D CMAKE_Fortran_COMPILER=ftn \\
  -D PKG_MANYBODY=ON \\
  -D PKG_ML-PACE=ON \\
  -D PKG_ML-SNAP=ON \\
  -D PKG_DIFFRACTION=ON \\
  -D PKG_SHOCK=ON \\
  -D PKG_EXTRA-PAIR=ON \\
  -D PKG_EXTRA-FIX=ON \\
  -D PKG_PLUMED=ON \\
  -D PKG_PTM=ON \\
  -C ../cmake/presets/kokkos-hip.cmake"

echo
read -p "Is this configuration correct? (y/n): " answer
case "$answer" in
    y|Y )
        echo ">>> Proceeding with build..."
        ;;
    n|N )
        cline=`echo "$LINENO+11`
        echo ">>> Build cancelled, add the cmake modules you want at line $cline and run `basename $0 ` cmake"
        exit 0
        ;;
    * )
        echo "Invalid response. Exiting."
        exit 1
        ;;
esac

cmake ../cmake \
  -D LAMMPS_BIGBIG:BOOL=ON \
  -D LAMMPS_SMALLBIG:BOOL=OFF \
  -D LAMMPS_SMALLSMALL:BOOL=OFF \
  -D CMAKE_C_COMPILER=cc \
  -D CMAKE_CXX_COMPILER=CC \
  -D CMAKE_Fortran_COMPILER=ftn \
  -D PKG_MANYBODY=ON \
  -D PKG_ML-PACE=ON \
  -D PKG_ML-SNAP=ON \
  -D PKG_DIFFRACTION=ON \
  -D PKG_SHOCK=ON \
  -D PKG_EXTRA-PAIR=ON \
  -D PKG_EXTRA-FIX=ON \
  -D DOWNLOAD_PLUMED=yes \
  -D PLUMED_MODE=static \
  -D PKG_PLUMED=ON \
  -D PKG_PTM=ON \
  -C ../cmake/presets/kokkos-hip.cmake

echo ">>> Building LAMMPS..."
make -j16

if [ $? -eq 0 ]
then
    echo ">>> Success!"
    echo ">>> Executable located at:"
    echo "    $(pwd)/lmp"
    echo ">>> Dont forget to update your submission scripts accordingly!"
    exit 0
else
    echo ">>> ERROR: Something bad happened, try again"
    exit 1
fi


