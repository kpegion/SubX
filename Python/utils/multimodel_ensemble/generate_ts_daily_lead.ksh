#!/bin/ksh
# Generate a file to create daily multimodel ensemble averages.
#
# Created by Ray Bell (https://github.com/raybellwaves).

# User defined variables:
outdir=/place/with/lots/of/storage/
ftype=hindcast # hindcast, forecast
# Assume all models may edit this later
var=zg # pr, tas, ts, rlut, ua, va, zg
plev=500 # 200, 500, 850, 2m, sfc, toa, None
t=65 # -90 - 90
lon=304 # 0 - 359
subsampleS=1 # 0, 1
startS=1999-01-07 # YYYY-MM-DD
endS=2014-12-28 # YYYY-MM-DD

# Remove any files previously created
rm -rf create_ts_daily_lead.py

# Replace text in python template file
cat createts_daily_lead_template.py\
| sed 's|outdir|'${outdir}'|g'\
| sed 's/ftype/'${ftype}'/g'\
| sed 's/var/'${var}'/g'\
| sed 's/plev/'${plev}'/g'\
| sed 's/lat/'${lat}'/g'\
| sed 's/lon/'${lon}'/g'\
| sed 's/subsampleS/'${subsampleS}'/g'\
| sed 's/startS/'${startS}'/g'\
| sed 's/endS/'${endS}'/g'\
> create_ts_daily_lead.py

# This section submits the python scripts on a HPC.
# Turned off in default
if [ 1 -eq 0 ];then
    rm -rf logs/*
    mkdir -p logs
    bsub < submit_scripts/submit_create_ts_daily_lead.sh
fi
