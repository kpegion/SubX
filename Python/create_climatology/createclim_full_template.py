""" Create SubX daily climatology.

The file is filled in by generate_ts_clim.ksh.
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


url = 'http://iridl.ldeo.columbia.edu/SOURCES/.Models/.SubX/'
ddir = outPath+ft+'/'+mo+'/'+va+'/'+str(pl)+'/daily/full/'
outclimDir = outPath+ft+'/'+mo+'/'+va+'/'+str(pl)+'/daily/clim/'
if not os.path.isdir(outclimDir):
    os.makedirs(outclimDir)
climfname = 'day_clim.nc'
sclimfname = 'smooth_day_clim.nc'

# Find out how many ensembles associated with the model:
_rd = xr.open_dataarray(url+ins+'/.'+mo+'/.'+ft+'/.'+va+'/dods')
nens = len(_rd.M.values)

# Use solution given in https://bit.ly/2xyhjCy
_l = []
for e in range(1, nens+1):
    ens = 'e%d' % e
    #_l.append(xr.open_mfdataset(ddir+'*.'+ens+'.nc',autoclose=True))
    ds = xr.open_mfdataset(ddir+'*.e*.nc',concat_dim='M',autoclose=True)

ds = xr.concat(_l, dim='M')
# Drop 1 dimensional coordinates
ds = ds.squeeze()
# Obtain data varialbe
da = ds[va]

# Ensemble mean
da_ensmean = da.mean(dim='M')
da_ensmean.to_netcdf(ddir+'day_ensmean.nc') # save ensemble mean

# Average daily data
da_day_clim = da_ensmean.groupby('S.dayofyear').mean('S')

# Save file
da_day_clim.to_netcdf(outclimDir+climfname)

# Pad the daily climatolgy with nans
x = np.empty((366, len(da_day_clim.L),len(da_day_clim.Y),len(da_day_clim.X)))
x.fill(np.nan)
_da = xr.DataArray(x, coords=[np.linspace(1, 366, num=366, dtype=np.int64),
                              da_day_clim.L,da_day_clim.Y,da_day_clim.X], dims = da_day_clim.dims)
da_day_clim_wnan = da_day_clim.combine_first(_da)

# Period rolling twice to make it triangular smoothing
# See https://bit.ly/2H3o0Mf
da_day_clim_smooth = da_day_clim_wnan.copy()
for i in range(2):
    # Extand the DataArray to allow rolling to do periodic
    da_day_clim_smooth = xr.concat([da_day_clim_smooth[-15:],
                                   da_day_clim_smooth,
                                   da_day_clim_smooth[:15]],
                                   'dayofyear')
    # Rolling mean
    da_day_clim_smooth = da_day_clim_smooth.rolling(dayofyear=31,
                                                    center=True,
                                                    min_periods=1).mean()
    da_day_clim_smooth = xr.DataArray(da_day_clim_smooth)


# Drop periodic boundaries
da_day_clim_smooth = da_day_clim_smooth[slice(30, -30),:,:,:]


# Save file
da_day_clim_smooth.to_netcdf(outclimDir+sclimfname)

