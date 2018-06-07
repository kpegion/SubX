""" Create SubX daily anomalies.

The file is filled in by generate_ts_anom.ksh.
"""
import os
import xarray as xr
import numpy as np


# Inputs
outPath = 'outdir'
ft = 'ftype'
mo = 'mod'
ins = 'inst'
va = 'var'
pl = plev
yv = lat.0
xv = lon.0

ysave = str(int(yv))
xsave = str(int(xv))
url = 'http://iridl.ldeo.columbia.edu/SOURCES/.Models/.SubX/'
ddir = outPath+ft+'/'+mo+'/'+va+'/'+str(pl)+'/daily/ts/'
outclimDir = outPath+ft+'/'+mo+'/'+va+'/'+str(pl)+'/daily/clim/'
climfname = 'smooth_day_clim.y'+ysave+'.x'+xsave+'.nc'
outanomDir = outPath+ft+'/'+mo+'/'+va+'/'+str(pl)+'/daily/anom/'
if not os.path.isdir(outanomDir):
    os.makedirs(outanomDir)
anomfname = 'daily_anomalies.y'+ysave+'.x'+xsave+'.nc'

# Find out how many ensembles associated with the model:
_rd = xr.open_dataarray(url+ins+'/.'+mo+'/.'+ft+'/.'+va+'/dods')
nens = len(_rd.M.values)

_l = []
for e in range(1, nens+1):
    ens = 'e%d' % e
    _l.append(xr.open_mfdataset(ddir+'*.'+ens+'.y'+ysave+'.x'+xsave+'.nc',
                                autoclose=True))
ds = xr.concat(_l, dim='M')
# Drop 1 dimensional coordinates
ds = ds.squeeze()
# Obtain data varialbe
da = ds[va]
    
# Read in the daily climatology
da_day_clim_s = xr.open_dataarray(outclimDir+climfname)
    
da_day_anom = da.groupby('S.dayofyear') - da_day_clim_s
da_day_anom.to_netcdf(outanomDir+anomfname)
