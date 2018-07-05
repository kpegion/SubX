""" Create ERA-Interim daily anomalies.

The file is filled in by generate_obs_ts_anom.ksh.
"""
import os
import pandas as pd


# Sections of code to run
download_data = 1 # 1, 0. conda acivate ECMWF
create_anom = 0 # 1, 0. conda activate SubX
create_mme_anom = 0 # 1, 0. conda activate SubX

# Inputs
moPath = 'moddir'
ft = 'ftype'
mo = 'mod'
ins = 'inst'
va = 'var'
pl = plev
yv = lat.0
xv = lon.0
subsampletime = subsampleS
starttime = 'startS'
endtime = 'endS'
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
obsclimPath = obsPath+'daily/SubX/clim/'
if not os.path.isdir(obsclimPath):
    os.makedirs(obsclimPath)
obsanomPath = obsPath+'daily/SubX/anom/'
if not os.path.isdir(obsanomPath):
    os.makedirs(obsanomPath)
obsfname = '1995-2017.y'+ysave+'.x'+xsave+'.nc'
obsclimfname = 'day_clim.y'+ysave+'.x'+xsave+'.SubX.'+mo+'.nc'
obssclimfname = 'smooth_day_clim.y'+ysave+'.x'+xsave+'.SubX.'+mo+\
                '.nc'
obsanomfname = 'daily_anomalies.y'+ysave+'.x'+xsave+'.SubX.'+mo+'.nc'

# Sub-sample time
if 0 == subsampletime:
    _rd = xr.open_dataarray(url+ins+'/.'+mo+'/.'+ft+'/.'+va+'/dods')
    starttime = pd.Timestamp(_rd.S.values[0]).strftime('%Y-%m-%d')
    endtime = pd.Timestamp(_rd.S.values[-1]).strftime('%Y-%m-%d')
# Update file names
anomfname = starttime+'.'+endtime+'.'+anomfname
obsclimfname = starttime+'.'+endtime+'.'+obsclimfname
obssclimfname = starttime+'.'+endtime+'.'+obssclimfname
obsanomfname = starttime+'.'+endtime+'.'+obsanomfname

if download_data == 1:
    from ecmwfapi import ECMWFDataServer


    server = ECMWFDataServer()
    server.retrieve({"class": "ei",
                     "dataset": "interim",
                     "date": "1995-01-01/to/2017-12-31",
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


if create_anom == 1:
    import xarray as xr
    import numpy as np


    da = xr.open_dataarray(obsPath+'6hrly/'+obsfname) 
    if va == 'zg':
        # Convert geopotential to geopotential height
        da = da/9.80665

    # Aveage 6 hourly data to daily data
    da = da.resample(time='1D').mean()

    # Put observationis into model format
    # Open model anomaly file
    _da = xr.open_dataarray(anomDir+anomfname)
    if 'M' in _da.coords:
        if _da.M.size > 1:
            obs = _da.isel(M=0).drop('M').copy()
        else:
            obs = _da.drop('M').copy()
    else:
        obs = _da.copy()
    for i, _L in enumerate(_da.L):
        _Sindex = _da.S + pd.Timedelta(str(i)+' days')
        obs[:, i] = da.sel(time=_Sindex)

    # Create climatology same as model
    obs_day_clim = obs.groupby('S.dayofyear').mean('S')
    obs_day_clim.to_netcdf(obsclimPath+obsclimfname)
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
    obs_day_clim_smooth.to_netcdf(obsclimPath+obssclimfname)

    obs_da_anom = obs.groupby('S.dayofyear') - obs_day_clim_smooth
    obs_da_anom = obs_da_anom.drop('dayofyear')
    obs_da_anom.to_netcdf(obsanomPath+obsanomfname)


if create_mme_anom == 1:
    import xarray as xr
    import numpy as np


    
    obsanomtmpfname = obsanomfname.replace('mod', '%(m)s')
    alllist = ['30LCESM1', '46LCESM1', 'CCSM4', 'FIMr1p1', 'GEFS',
               'GEM', 'GEOS_V2p1', 'NESM']
    # Create an observed multi-ensemble ensembl file the same way
    # the modle mme is created: Average all the fiels todether
    # Read in one model to get leadtime coords
    fname = obsanomtmpfname % {'m':'CCSM4'}
    da = xr.open_dataarray(obsanomPath+fname)
    _dates = pd.date_range(starttime, endtime, freq='D')
    _L = [ pd.Timedelta(12,'h') + pd.Timedelta(days=i) for i in range(45) ]
    x = np.empty((len(_dates), len(_L)))
    x.fill(np.nan)
    obs_mme_da = xr.DataArray(x, coords={'X': da.X, 'L': da.L, 'Y': da.Y,
                                         'P': da.P, 'S': _dates},
                              dims=['S', 'L'])

    for _, mo in enumerate(alllist):
        fname = obsanomtmpfname % {'m':mo}
        da = xr.open_dataarray(obsanomPath+fname)
        obs_mme_da = xr.concat([obs_mme_da, da], dim='_S').mean('_S')

    obs_mme_da = obs_mme_da.dropna('S')
    fname = obsanomtmpfname % {'m':'MME'}
    obs_mme_da.to_netcdf(outmmeDir+fname)
