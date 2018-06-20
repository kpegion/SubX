#!/bin/ksh
# Generate a file to create NAO index.
#
# Created by Ray Bell (https://github.com/raybellwaves).

# User defined variables:
# Same as those specified in download_data/generate_ts_py_ens_files.ksh
moddir=/place/with/lots/of/storage/SubX/
ftype=hindcast # hindcast, forecast
mod=CCSM4 # 30LCESM1, 46LCESM1, CCSM4, CFSv2, FIMr1p1, GEFS, GEM, GEOS_V2p1, NESM
inst=RSMAS # CESM,    CESM,     RSMAS, NCEP,  ESRL,    EMC,  ECCC, GMAO,     NRL 
var=zg # pr, tas, ts, rlut, ua, va, zg
plev=500 # 200, 500, 850, 2m, sfc, toa, None
nlat=65 # -90 - 90
nlon=305 # 0 - 359
slat=43 # -90 - 90
slon=323 # 0 - 359
subsampleS=1 # 0, 1
startS=1999-01-07 # YYYY-MM-DD
endS=2014-12-28 # YYYY-MM-DD
obsdir=/place/with/lots/of/storage/ERA-Interim/

# Remove any files previously created
rm -rf create_NAO_index.py

# Replace text in python template file for each ensemble member
cat createNAO_index_template.py\
| sed 's|moddir|'${moddir}'|g'\
| sed 's/ftype/'${ftype}'/g'\
| sed 's/mod/'${mod}'/g'\
| sed 's/inst/'${inst}'/g'\
| sed 's/var/'${var}'/g'\
| sed 's/plev/'${plev}'/g'\
| sed 's/nlat/'${nlat}'/g'\
| sed 's/nlon/'${nlon}'/g'\
| sed 's/slat/'${slat}'/g'\
| sed 's/slon/'${slon}'/g'\
| sed 's/subsampleS/'${subsampleS}'/g'\
| sed 's/startS/'${startS}'/g'\
| sed 's/endS/'${endS}'/g'\
| sed 's|obsdir|'${obsdir}'|g'\
> create_NAO_index.py

# This section submits the python scripts on a HPC.
# Turned off in default
if [ 1 -eq 0 ];then
    rm -rf logs/*
    mkdir -p logs
    bsub < submit_scripts/submit_create_NAO_index.sh
fi
