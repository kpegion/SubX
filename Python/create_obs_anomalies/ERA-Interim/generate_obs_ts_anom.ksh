#!/bin/ksh
# Generate a file to create ERA-Interim anomalies.
#
# Created by Ray Bell (https://github.com/raybellwaves).

# User defined variables:
# Same as those specified in download_data/generate_ts_py_ens_files.ksh
moddir=/place/with/lots/of/storage/SubX/
ftype=hindcast # hindcast, forecast
mod=CCSM4 # 30LCESM1, 46LCESM1, CCSM4, CFSv2, FIMr1p1, GEFS, GEM, GEOS_V2p1, NESM
inst=RSMAS # CESM, 
var=zg # pr, tas, ts, rlut, ua, va, zg
plev=500 # 200, 500, 850, 2m, sfc, toa, None
lat=65 # -90 - 90
lon=305 # 0 - 359
obsdir=/place/with/lots/of/storage/ERA-Interim/

# Remove any files previously created
rm -rf create_obs_ts_anomalies.py

# Replace text in python template file for each ensemble member
cat createobsanom_ts_template.py\
| sed 's|moddir|'${moddir}'|g'\
| sed 's/ftype/'${ftype}'/g'\
| sed 's/mod/'${mod}'/g'\
| sed 's/inst/'${inst}'/g'\
| sed 's/var/'${var}'/g'\
| sed 's/plev/'${plev}'/g'\
| sed 's/lat/'${lat}'/g'\
| sed 's/lon/'${lon}'/g'\
| sed 's|obsdir|'${obsdir}'|g'\
> create_obs_ts_anomalies.py

# This section submits the python scripts on a HPC.
# Turned off in default
if [ 1 -eq 0 ];then
    rm -rf logs/*
    mkdir -p logs
    bsub < submit_scripts/submit_create_obs_ts_anom.sh
fi
