#!/bin/bash

# exit on error
set -e
# turn on command echoing
set -v
# make sure that the current directory is the one where this script is
cd ${0%/*}

for f in out/brownian_part_????_00000001.nc ; do
    ../../extract_aero_size --mass --dmin 1e-10 --dmax 1e-4 --nbin 220 ${f/_00000001.nc/}
done
../../numeric_average out/brownian_part_aero_size_mass_average.txt out/brownian_part_????_aero_size_mass.txt
../../extract_sectional_aero_size --mass out/brownian_sect
../../numeric_diff --by col --rel-tol 0.3 out/brownian_sect_aero_size_mass.txt out/brownian_part_aero_size_mass_average.txt
