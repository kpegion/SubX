#!/bin/ksh
# Generate a file to create anomalies.
#
# Created by Ray Bell (https://github.com/raybellwaves).
# Edited for full lat-lon grid by Kirsten Mayer

# User defined variables:
# Same as those specified in download_data/generate_ts_py_ens_files.ksh
outdir=/path/with/lots/of/space/
ftype=hindcast # hindcast, forecast
mod=CCSM4 # 30LCESM1, 46LCESM1, CCSM4, CFSv2, FIMr1p1, GEFS, GEM, GEOS_V2p1, NESM
inst=RSMAS # CESM,    CESM,     RSMAS, NCEP,  ESRL,    EMC,  ECCC, GMAO,     NRL
var=zg # pr, tas, ts, rlut, ua, va, zg
plev=500 # 200, 500, 850, 2m, sfc, toa, None
subsampleS=1 # 0, 1
startS=1999-01-07 # YYYY-MM-DD
endS=2014-12-28 # YYYY-MM-DD

# Remove any files previously created
rm -rf create_full_anomalies.py

# Replace text in python template file
cat createanom_full_template.py\
| sed 's|outdir|'${outdir}'|g'\
| sed 's/ftype/'${ftype}'/g'\
| sed 's/mod/'${mod}'/g'\
| sed 's/inst/'${inst}'/g'\
| sed 's/var/'${var}'/g'\
| sed 's/plev/'${plev}'/g'\
| sed 's/subsampleS/'${subsampleS}'/g'\
| sed 's/startS/'${startS}'/g'\
| sed 's/endS/'${endS}'/g'\
> create_full_anomalies.py

# This section submits the python scripts on a HPC.
# Turned off in default
if [ 1 -eq 0 ];then
    rm -rf logs/*
    mkdir -p logs
    bsub < submit_scripts/submit_create_full_anom.sh
fi
