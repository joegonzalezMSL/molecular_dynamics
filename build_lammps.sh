#!/bin/bash
module load craype-accel-amd-gfx90a
module load PrgEnv-amd
module load rocm/5.7.1
module load cray-python/3.9.12.1   #for ace installing

make clean-all

make lib-pace args="-b"
make lib-hdnnp args="-b"
make yes-ml-pace

make yes-KOKKOS
make yes-ML-SNAP
make yes-SHOCK
make yes-ML-PACE
make yes-DIFFRACTION
make yes-MANYBODY
make yes-ML-HDNNP
make yes-EXTRA-PAIR

#make  crusher_kokkos -j 16
make  frontier_kokkos -j 16

#cp lmp_crusher_kokkos ../bin/
cp frontier_kokkos  ../bin/

