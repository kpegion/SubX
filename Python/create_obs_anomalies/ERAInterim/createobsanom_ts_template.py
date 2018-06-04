""" Create ERAInterim daily anomalies.

The file is filled in by generate_obs_ts_anom.ksh.
"""
import os


# Sections of code to run
download_data = 1 # 1, 0. conda acivate ECMWF
create_clim = 0 # 1, 0. conda activate SubX
create_anom = 0 # 1, 0. conda activate SubX

# Inputs
modDir = 'place/with/lots/of/storage/'
ft = 'hindcast'
mo = 'CCSM4'
ins = 'RSMAS'
va = 'zg'
plev = 500
yv = 65
xv = 305
obsDir = '/obs/place/with/lots/of/storage/'+va+'/'+str(pl)+'/'


if va == 'zg':
   paramid = "129.128"

anomDir = modDir+ft+'/'+mo+'/'+va+'/'+str(pl)+'/daily/anom/'
ysave = str(int(yv))
xsave = str(int(xv))
anomfname = 'daily_anomalies.y'+ysave+'.x'+xsave+'.nc'
areaid = ysave+'/'+xsave+'/'+ysave+'/'+xsave

if not os.path.isdir(obsDir+'6hrly/'):
    os.makedirs(obsDir+'6hrly/')
obsclimDir = obsDir+'daily/clim/'
if not os.path.isdir(obsclimDir):
    os.makedirs(obsclimDir)
obsanomDir = obsDir+'daily/anom/'
if not os.path.isdir(obsanomDir):
    os.makedirs(obsanomDir):
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
                     "target": obsDir+obsfname})

