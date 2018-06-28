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

ens_anom = False # True if individual ensemble anomalies are wanted
ensmean_anom = True # True if ensemble mean anomalies are wanted

url = 'http://iridl.ldeo.columbia.edu/SOURCES/.Models/.SubX/'
ddir = outPath+ft+'/'+mo+'/'+va+'/'+str(pl)+'/daily/full/'
outclimDir = outPath+ft+'/'+mo+'/'+va+'/'+str(pl)+'/daily/clim/'
climfname = 'smooth_day_clim.nc'
outanomDir = outPath+ft+'/'+mo+'/'+va+'/'+str(pl)+'/daily/anom/'
if not os.path.isdir(outanomDir):
    os.makedirs(outanomDir)
anomfname = 'daily_anomalies.nc'
i_anomfname = 'daily_ensanom.nc'


if ens_anom:
    # Find out how many ensembles associated with the model:
    _rd = xr.open_dataarray(url+ins+'/.'+mo+'/.'+ft+'/.'+va+'/dods')
    nens = len(_rd.M.values)

    _l = []
    for e in range(1, nens+1):
        ens = 'e%d' % e
        _l.append(xr.open_mfdataset(ddir+'*.'+ens+'.nc',
                                    autoclose=True))
    ds = xr.concat(_l, dim='M')
    # Drop 1 dimensional coordinates
    ds = ds.squeeze()
    # Obtain data varialbe
    da = ds[va]
    del(ds)
    # Read in the daily climatology
    da_day_clim_s = xr.open_dataarray(outclimDir+climfname)
        
    da_day_anom = da.groupby('S.dayofyear') - da_day_clim_s
    del(da)
    del(da_day_clim_s)
    da_day_anom.to_netcdf(outanomDir+i_anomfname)

if ensmean_anom:
    # Read in the ensemble mean
    da_ensmean = xr.open_dataarray(ddir+'day_ensmean.nc')
    
    # Read in the daily climatology
    da_day_clim_s = xr.open_dataarray(outclimDir+climfname)
    
    da_day_anom = da_ensmean.groupby('S.dayofyear') - da_day_clim_s
    del(da_ensmean)
    del(da_day_clim_s)
    da_day_anom.to_netcdf(outanomDir+anomfname)
