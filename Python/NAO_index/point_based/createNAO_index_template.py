""" Create NAO index.

The file is filled in by generate_NAO_index.ksh.
"""
import os
import xarray as xr
import pandas as pd


# Sections of code to run
forecast = 1 # 1, 0
mme_forecast = 0 # 1, 0
ERA_Interim = 0 # 1, 0

# Inputs
moPath = 'moddir'
ft = 'ftype'
mo = 'mod'
ins = 'inst'
va = 'var'
pl = plev
nyv = nlat.0
nxv = nlon.0
syv = slat.0
sxv = slon.0
subsampletime = subsampleS
starttime = 'startS'
endtime = 'endS'
obsPath = 'obsdir'+va+'/'+str(pl)+'/'

nysave = str(int(nyv))
nxsave = str(int(nxv))
sysave = str(int(syv))
sxsave = str(int(sxv))

anomDir = moPath+ft+'/'+mo+'/'+va+'/'+str(pl)+'/daily/anom/'
anomfname = 'daily_anomalies.y'
obsanomPath = obsPath+'daily/SubX/anom/'
obsanomfname = 'daily_anomalies.y'

NAOpath = moPath+ft+'/'+mo+'/'+va+'/'+str(pl)+'/daily/NAO/point_based/'
if not os.path.isdir(NAOpath):
    os.makedirs(NAOpath)
obsNAOpath = obsPath+'daily/SubX/NAO/point_based/'
if not os.path.isdir(obsNAOpath):
    os.makedirs(obsNAOpath)
NAOfname = 'np.y'+nysave+'.x'+nxsave+'.sp.y'+sysave+'.x'+sxsave+'.nc'
obsNAOfname = 'np.y'+nysave+'.x'+nxsave+'.sp.y'+sysave+'.x'+sxsave+\
'.SubX.'+mo+'.nc'

# Sub-sample time
if 0 == subsampletime:
    _rd = xr.open_dataarray(url+ins+'/.'+mo+'/.'+ft+'/.'+va+'/dods')
    starttime = pd.Timestamp(_rd.S.values[0]).strftime('%Y-%m-%d')
    endtime = pd.Timestamp(_rd.S.values[-1]).strftime('%Y-%m-%d')
# Update file names
anomfname = starttime+'.'+endtime+'.'+anomfname
obsanomfname = starttime+'.'+endtime+'.'+obsanomfname
NAOfname = starttime+'.'+endtime+'.'+NAOfname
obsNAOfname = starttime+'.'+endtime+'.'+obsNAOfname

if forecast == 1:
    # Read in north point
    nda = xr.open_dataarray(anomDir+anomfname+nysave+'.x'+nxsave+'.nc')
    # Read in south point
    sda = xr.open_dataarray(anomDir+anomfname+sysave+'.x'+sxsave+'.nc')

    # Loop over ensembles
    for i, e in enumerate(nda.M):
        esave = str(int(e))
        _np = nda.sel(M=e)
        _sp = sda.sel(M=e)

        nao = (_sp - _np) / (_sp - _np).std(dim='S')
        nao.attrs['long_name'] = 'NAO'
        nao.to_netcdf(NAOpath+'e'+esave+'.'+NAOfname)

    # Ensemble mean
    _np = nda.mean(dim='M')
    _sp = sda.mean(dim='M')
    nao = (_sp - _np) / (_sp - _np).std(dim='S')
    nao.attrs['long_name'] = 'NAO'
    nao.to_netcdf(NAOpath+'emean.'+NAOfname)
    

if mme_forecast == 1:
    nda = xr.open_dataarray(anomDir+anomfname+nysave+'.x'+nxsave+'.nc')
    sda = xr.open_dataarray(anomDir+anomfname+sysave+'.x'+sxsave+'.nc')    

    nao = (sda - nda) / (sda - nda).std(dim='S')
    nao.attrs['long_name'] = 'NAO'
    nao.to_netcdf(NAOpath+'emean.'+NAOfname)


if ERA_Interim == 1:
    nda = xr.open_dataarray(obsanomPath+obsanomfname+nysave+'.x'+nxsave+\
                            '.SubX.'+mo+'.nc')
    sda = xr.open_dataarray(obsanomPath+obsanomfname+sysave+'.x'+sxsave+\
                            '.SubX.'+mo+'.nc')

    nao = (sda - nda) / (sda - nda).std(dim='S')
    nao.attrs['long_name'] = 'NAO'
    nao.to_netcdf(obsNAOpath+obsNAOfname)

