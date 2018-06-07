""" Create ERA-Interim daily anomalies.

The file is filled in by generate_obs_ts_anom.ksh.
"""
import os


# Sections of code to run
download_data = 1 # 1, 0. conda acivate ECMWF
create_clim = 0 # 1, 0. conda activate SubX
create_anom = 0 # 1, 0. conda activate SubX

# Inputs
moPath = 'moddir'
ft = 'ftype'
mo = 'mod'
ins = 'inst'
va = 'var'
pl = plev
yv = 65.0
xv = 305.0
obsPath = 'obsdir'+va+'/'+str(pl)+'/'


if va == 'zg':
   paramid = "129.128"

anomDir = moPath+ft+'/'+mo+'/'+va+'/'+str(pl)+'/daily/anom/'
ysave = str(int(yv))
xsave = str(int(xv))
anomfname = 'daily_anomalies.y'+ysave+'.x'+xsave+'.nc'
areaid = ysave+'/'+xsave+'/'+ysave+'/'+xsave

if not os.path.isdir(obsPath+'6hrly/'):
    os.makedirs(obsPath+'6hrly/')
obsclimPath = obsPath+'daily/clim/'
if not os.path.isdir(obsclimPath):
    os.makedirs(obsclimPath)
obsanomPath = obsPath+'daily/anom/'
if not os.path.isdir(obsanomPath):
    os.makedirs(obsanomPath)
obsfname = '1999-2016.y'+ysave+'.x'+xsave+'.nc'
obsdayfname = '1999-2016.y'+ysave+'.x'+xsave+'.'+mo+'.nc'
obsclimfname = 'day_clim_1999-2016.y'+ysave+'.x'+xsave+'.'+mo+'.nc'
obssclimfname = 'smooth_day_clim_1999-2016.y'+ysave+'.x'+xsave+'.'+mo+'.nc'
obsanomfname = 'daily_anomalies_1999-2016.y'+ysave+'.x'+xsave+'.'+mo+'.nc'


if download_data == 1:
    from ecmwfapi import ECMWFDataServer


    server = ECMWFDataServer()
    server.retrieve({"class": "ei",
                     "dataset": "interim",
                     "date": "1999-01-01/to/2016-12-31",
                     "expver": "1",
                     "grid": "1.00/1.00",
                     "levelist": str(plev),
                     "levtype": "pl",
                     "param": paramid,
                     "step": "0",
                     "stream": "oper",
                     "time": "00/06/12/18",
                     "type": "an",
                     "area": areaid,
                     "format": "netcdf",
                     "target": obsPath+'6hrly/'+obsfname})


if create_clim == 1:
    import xarray as xr
    import pandas as pd
    import numpy as np


    da = xr.open_dataarray(obsPath+'6hrly/'+obsfname) 
    if va == 'zg':
        # Convert geopotential to geopotential height
        da = da/9.80665

    # Aveage 6 hourly data to daily data
    da = da.resample(time='1D').mean()

    # Put observationis into model format
    _da = xr.open_dataarray(anomDir+anomfname)
    obs = _da.mean(dim='M').copy()
    for i, _L in enumerate(_da.L):
        _Sindex = _da.S + pd.Timedelta(str(i)+' days')
        obs[:, i] = da.sel(time=_Sindex)
    obs.to_netcdf(obsPath+'daily/'+obsdayfname)

    # Create climatology same as model
    obs_day_clim = obs.groupby('S.dayofyear').mean('S')
    obs_day_clim.to_netcdf(obsPath+'daily/clim/'+obsclimfname)
    x = np.empty((366, len(obs_day_clim.L)))
    x.fill(np.nan)
    _da = xr.DataArray(x, coords=[np.linspace(1, 366, num=366, dtype=np.int64),
                                  obs_day_clim.L], dims = obs_day_clim.dims)
    obs_day_clim_wnan = obs_day_clim.combine_first(_da)
    obs_day_clim_smooth = obs_day_clim_wnan.copy()
    for i in range(2):
        obs_day_clim_smooth = xr.concat([obs_day_clim_smooth[-15:],
                                        obs_day_clim_smooth,
                                        obs_day_clim_smooth[:15]],
                                        'dayofyear')
        obs_day_clim_smooth = obs_day_clim_smooth.rolling(dayofyear=31,
                                                          center=True,
                                                          min_periods=1).mean()
        obs_day_clim_smooth = obs_day_clim_smooth.isel(dayofyear=slice(15,
                                                                       -15))
    obs_day_clim_smooth = obs_day_clim_smooth.sel(\
                          dayofyear=obs_day_clim.dayofyear)
    obs_day_clim_smooth.to_netcdf(obsPath+'daily/clim/'+obssclimfname)
