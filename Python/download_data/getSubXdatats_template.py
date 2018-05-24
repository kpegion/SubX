""" Download SubX data from IRI.

Template file to be used with generate_ts_py_ens_files.ksh.
"""
import os
import glob
import xarray as xr
import pandas as pd
import numpy as np


# Inputs
rl = 'url'
outPath = 'outdir'
ft = 'ftype'
mo = 'mod'
ins = 'inst'
va = 'var'
pl = plev
yv = lat.0
xv = lon.0
en = ens.0

inFname = rl+'.'+ins+'/.'+mo+'/.'+ft+'/.'+va+'/dods'
remote_data = xr.open_dataarray(inFname)
if len(remote_data.dims) == 6:
    da = remote_data.sel(P=plev, M=en, Y=yv, X=xv)
if len(remote_data.dims) == 5:
    da = remote_data.sel(M=en, Y=yv, X=xv)
    
outDir = outPath+ft+'/'+mo+'/'+va+'/'+str(pl)+'/daily/ts/'
if not os.path.isdir(outDir):
    os.makedirs(outDir)
    
# Check if any files have been created so they are not downloaded again
filescreated = glob.glob(outDir+'*.e'+str(int(en))+'.y'+str(int(yv))+\
                         '.x'+str(int(xv))+'.nc')
nfilescreated = len(filescreated)
if nfilescreated != 0:
    filescreated.sort()
    # Remove last file created incase stopped while saving
    _lastfile = filescreated[-1]
    os.unlink(_lastfile)
    # Find the date and index of the last created file
    # Split the string by / and get the first 8 chars
    _lastdate = _lastfile.split('/')[-1][0:8]
    _lastyear = _lastdate[0:4]
    _lastmonth = _lastdate[4:6]
    _lastday = _lastdate[6:8]
    ts = pd.Timestamp(_lastyear+'-'+_lastmonth+'-'+_lastday+' 00:00:00')
    # Find the index of this in da.S
    datesdf = da.S.to_dataframe()
    _icstart = datesdf.index.get_loc(ts)
else:
    _icstart = 0
    
for ic in range(_icstart, len(da.S.values)):
    # Check if data exists for this start date otherwise skip
    da2 = da.sel(S=da.S.values[ic])
    if not np.all(np.isnan(da2)):
        # Convert to a pandas.Timestamp to get year, month, data
        date = pd.Timestamp(da.S.values[ic])
        year = str(date.year)
        # Use zfill to pad with 0
        month = str(date.month).zfill(2)
        day = str(date.day).zfill(2)
                    
        # Out file name
        ofname = year+month+day+'.e'+str(int(en))+'.y'+str(int(yv))+'.x'+\
        str(int(xv))+'.nc'
        
        # Select the 1D field and keep the other dimensions
        da2 = da.sel(S=da.S.values[ic])
        # Data often finishes before end of file
        if len(remote_data.dims) == 6:
            try:
                da2 = da2.expand_dims('S').expand_dims('M').expand_dims('P').\
                      expand_dims('Y').expand_dims('X')
            except IndexError:
                exit('All data likely downloaded. You can check '+\
                     inFname[:-4]+'#views to see if it can generate an image.')
        else:
            try:
                da2 = da2.expand_dims('S').expand_dims('M').expand_dims('Y').\
                      expand_dims('X')
            except IndexError:
                exit('All data likely downloaded. You can check '+\
                     inFname[:-4]+'#views to see if it can generate an image.')            
        # Save file
        da2.to_netcdf(outDir+ofname)
