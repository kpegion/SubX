""" Create NAO index.

The file is filled in by generate_NAO_index.ksh.
"""
import os
import xarray as xr


# Sections of code to run
forecast = 1 # 1, 0
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
obsPath = 'obsdir'+va+'/'+str(pl)+'/'

nysave = str(int(nyv))
nxsave = str(int(nxv))
sysave = str(int(syv))
sxsave = str(int(sxv))

anomDir = moPath+ft+'/'+mo+'/'+va+'/'+str(pl)+'/daily/anom/'
anomfname = 'daily_anomalies.y'
obsanomPath = obsPath+'daily/anom/'
obsanomfname = 'daily_anomalies_1999-2016.y'

NAOpath = moPath+ft+'/'+mo+'/'+va+'/'+str(pl)+'/daily/NAO/point_based/'
if not os.path.isdir(NAOpath):
    os.makedirs(NAOpath)
obsNAOpath = obsPath+'daily/NAO/point_based/'
if not os.path.isdir(obsNAOpath):
    os.makedirs(obsNAOpath)
NAOfname = 'np.y'+nysave+'.x'+nxsave+'.sp.y'+sysave+'.x'+sxsave+'.nc'
obsNAOfname = '1999-2016.np.y'+nysave+'.x'+nxsave+'.sp.y'+sysave+'.x'+sxsave+\
'SubX'+mo+'.nc'

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
    

if ERA_Interim == 1:
    nda = xr.open_dataarray(obsanomPath+obsanomfname+nysave+'.x'+nxsave+\
                            '.SubX.'+mo+'.nc')
    sda = xr.open_dataarray(obsanomPath+obsanomfname+sysave+'.x'+sxsave+\
                            '.SubX.'+mo+'.nc')

    nao = (sda - nda) / (sda - nda).std(dim='S')
    nao.attrs['long_name'] = 'NAO'
    nao.to_netcdf(obsNAOpath+obsNAOfname)

