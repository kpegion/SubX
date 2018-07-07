""" Create SubX daily multi-model ensemble anomalies.

The file is filled in by generate_ts_daily_lead.ksh.
"""
import os
import xarray as xr
import numpy as np
import pandas as pd


# Inputs
outPath = 'outdir'
ft = 'ftype'
va = 'var'
pl = plev
yv = lat.0
xv = lon.0
subsampletime = subsampleS
starttime = 'startS'
endtime = 'endS'

ysave = str(int(yv))
xsave = str(int(xv))

outanomDir = outPath+ft+'/%(m)s/'+va+'/'+str(pl)+'/daily/anom/'
anomfname = 'daily_anomalies.y'+ysave+'.x'+xsave+'.nc'
outmmeDir = outPath+ft+'/MME/'+va+'/'+str(pl)+'/daily/anom/'
if not os.path.isdir(outmmeDir):
    os.makedirs(outmmeDir)
# Update file names
anomfname = starttime+'.'+endtime+'.'+anomfname

modellist = ['30LCESM1', '46LCESM1', 'CCSM4', 'FIMr1p1', 'GEFS',
             'GEM', 'GEOS_V2p1', 'NESM']
# create an empty multi-model ensemble file made up of
# days from startS and endS and leadtime of up to 45 days
# Read in one model to get leadtime coords
da = xr.open_dataarray(_moddir+anomfname)
_dates = pd.date_range(starttime, endtime, freq='D')
_L = [ pd.Timedelta(12,'h') + pd.Timedelta(days=i) for i in range(45) ]
x = np.empty((len(modellist), len(_dates), len(_L)))
x.fill(np.nan)
mme_ds = xr.DataArray(x, coords={'X': da.X, 'L': da.L, 'Y': da.Y,
                                 'P': da.P, 'S': _dates, 'model': modellist},
                      dims=['model', 'S', 'L'])
# Populate mme_da
for i, model in enumerate(modellist):
    _moddir = outanomDir % {'m':model}
    da = xr.open_dataarray(_moddir+anomfname)
    da = da.mean(dim='M')
    # Find indices to populate start date
    idates = np.ones(len(da.S), dtype=np.int16)
    for j in range(len(idates)):
        idates[j] = int(_dates.get_loc(da.S.values[j]))
    mme_ds[i,idates,0:len(da.L)] = da.values

# Keep start date if it has more than one model
_moddir = outanomDir % {'m':'CCSM4'}
da = xr.open_dataarray(_moddir+anomfname)
x2 = np.empty((len(_dates), len(_L)))
x2.fill(np.nan)
mme_da = xr.DataArray(x2, coords={'X': da.X, 'L': da.L, 'Y': da.Y,
                                 'P': da.P, 'S': _dates},
                      dims=['S', 'L'])

for i, _S in enumerate(mme_ds.S):
    if np.count_nonzero(~np.isnan(mme_ds.isel(S=i, L=1).values)) > 1:
        mme_da[i, :] = mme_ds.sel(S=_S).mean(dim='model')
# Drop missing values
mme_da = mme_da.dropna('S')
# Save data
mme_da.to_netcdf(outmmeDir+anomfname)



