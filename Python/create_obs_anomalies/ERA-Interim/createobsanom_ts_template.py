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
plev = plev
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
obsclimfname = 'smooth_day_clim_1999-2016.y'+ysave+'.x'+xsave+'.'+mo+'.nc'
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
                     "target": obsPath+obsfname})

