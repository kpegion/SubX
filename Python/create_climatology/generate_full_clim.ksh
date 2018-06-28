#!/bin/ksh
# Generate a file to create a climatology.
#
# Created by Ray Bell (https://github.com/raybellwaves).
# Edited for full lat-lon grid by Kirsten Mayer

# User defined variables:
# Same as those specified in download_data/generate_full_py_ens_files.ksh
outdir=/path/with/lots/of/space
ftype=hindcast # hindcast, forecast
mod=FIMr1p1 # 30LCESM1, 46LCESM1, CCSM4, CFSv2, FIMr1p1, GEFS, GEM, GEOS_V2p1, NESM
inst=ESRL # CESM,
var=zg # pr, tas, ts, rlut, ua, va, zg
plev=500 # 200, 500, 850, 2m, sfc, toa, None


# Remove any files previously created
rm -rf create_full_climatology.py

# Replace text in python template file for each ensemble member
cat createclim_full_template.py\
| sed 's|outdir|'${outdir}'|g'\
| sed 's/ftype/'${ftype}'/g'\
| sed 's/mod/'${mod}'/g'\
| sed 's/inst/'${inst}'/g'\
| sed 's/var/'${var}'/g'\
| sed 's/plev/'${plev}'/g'\
> create_full_climatology.py

# This section submits the python scripts on a HPC.
# Turned off in default
if [ 1 -eq 0 ];then
    rm -rf logs/*
    mkdir -p logs
    bsub < submit_scripts/submit_create_full_clim.sh
fi
