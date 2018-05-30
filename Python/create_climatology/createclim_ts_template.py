""" Create SubX daily climatology.

The file is filled in by generate_ts_clim.ksh.
"""
import os
import xarray as xr
import numpy as np


# Sections of code to run
gen_clim = 1 #1, 0
smooth_clim = 0 #1, 0

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
if not os.path.isdir(outclimDir):
    os.makedirs(outclimDir)
climfname = 'day_clim.y'+ysave+'.x'+xsave+'.nc'
sclimfname = 'smooth_day_clim.y'+ysave+'.x'+xsave+'.nc'

# Find out how many ensembles associated with the model:
_rd = xr.open_dataarray(url+ins+'/.'+mo+'/.'+ft+'/.'+va+'/dods')
nens = len(_rd.M.values)


if gen_clim == 1:
    # Use solution given in https://bit.ly/2xyhjCy
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
    
    # Ensemble mean
    da_ensmean = da.mean(dim='M')
    
    # Average daily data
    da_day_clim = da_ensmean.groupby('S.dayofyear').mean('S')

    # Save file
    da_day_clim.to_netcdf(outclimDir+climfname)
    

if smooth_clim == 1:
    da_day_clim = xr.open_dataarray(outclimDir+climfname)
    
    # Pad the daily climatolgy with nans
    x = np.empty((366, len(da_day_clim.L)))
    x.fill(np.nan)
    _da = xr.DataArray(x, coords=[np.linspace(1, 366, num=366, dtype=np.int64),
                                  da_day_clim.L], dims = da_day_clim.dims)
    da_day_clim_wnan = da_day_clim.combine_first(_da)
    
    # Period rolling twice to make it triangular smoothing
    # See https://bit.ly/2H3o0Mf
    da_day_clim_smooth = da_day_clim_wnan.copy()
    for i in range(2):
        # Extand the DataArray to allow rolling to do periodic
        da_day_clim_smooth = xr.concat(da_day_clim_smooth[-15,:],
                                       da_day_clim_smooth,
                                       da_day_clim_smooth[:,15],
                                       'dayofyear')
        # Rolling mean
        da_day_clim_smooth = da_day_clim_smooth.rolling(dayofyear=31,
                                                        center=True,
                                                        min_periods=1).mean()
        # Drop the periodic boundaries
        da_day_clim_smooth = da_day_clim_smooth.isel(dayofyear=slice(15, -15))
    # Extract the original days
    da_day_clim_smooth = da_day_clim_smooth.sel(dayofyear=da_day_clim.dayofyear
                                                )
    # Save file
    da_day_clim_smooth.to_netcdf(outclimDir+sclimfname)
