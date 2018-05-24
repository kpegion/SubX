#!/bin/ksh
# Generate individual files to allow downloading of each ensemble member in parallel.
#
# 5/16/18
# Created by Ray Bell (https://github.com/raybellwaves).

# User defined variables:
# See http://iridl.ldeo.columbia.edu/SOURCES/.Models/.SubX/ for a list of models availible.
# See http://cola.gmu.edu/kpegion/subx/data/priority1.html or
#http://cola.gmu.edu/kpegion/subx/data/priority2.html for a list of var abbreviations.
# See http://cola.gmu.edu/kpegion/subx/docs/SubXDataQuickReferenceGuide.pdf
#for notes on what presseure level is associated with the data.
#
outdir=/place/with/lots/of/storage/
ftype=hindcast # hindcast, forecast
mod=CCSM4 # 30LCESM1, 46LCESM1, CCSM4, CFSv2, FIMr1p1, GEFS, GEM, GEOS_V2p1, NESM
inst=RSMAS # CESM, 
var=zg # pr, tas, ts, rlut, ua, va, zg
plev=500 # 200, 500, 850, 2m, sfc, toa, None

# Default variables
url=http://iridl.ldeo.columbia.edu/SOURCES/.Models/.SubX/

# Remove any files previously created
rm -rf tmp.py
rm -rf *_e*.py

# Find out how many ensembles are associated with the model:

# Write python script
cat > tmp.py << EOF
import xarray as xr
_rd = xr.open_dataarray('${url}.${inst}/.${mod}/.${ftype}/.${var}/dods')
print(len(_rd.M.values))
EOF

# Run python script and return the number of ensembles
nens=`python tmp.py`
rm -rf tmp.py

for ens in {1..${nens}}; do
    # Replace text in python template file for each ensemble member
    cat getSubXdatafull_template.py\
    | sed 's|url|'${url}'|g'\
    | sed 's|outdir|'${outdir}'|g'\
    | sed 's/ftype/'${ftype}'/g'\
    | sed 's/mod/'${mod}'/g'\
    | sed 's/inst/'${inst}'/g'\
    | sed 's/var/'${var}'/g'\
    | sed 's/plev/'${plev}'/g'\
    | sed 's/ens/'${ens}'/g'\
    > getSubXdatafull_e${ens}.py
done

# This section submits the python scripts on a HPC.
# Turned off in default
if [ 1 -eq 0 ];then
    rm -rf logs/*
    rm -rf submit_scripts/*e*.sh
    mkdir -p logs
    for ens in {1..${nens}}; do
        # Replace text in submit template file
        cat submit_scripts/submit_full.sh | sed 's/ens/'${ens}'/g' > submit_scripts/submit_e${ens}.sh
        bsub < submit_scripts/submit_e${ens}.sh
    done
fi
