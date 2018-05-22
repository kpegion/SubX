""" Download SubX data from IRI.

Template file to be used with generate_ts_py_ens_files.ksh.
"""
import os
import glob
import xarray as xr
import pandas as pd

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
    
# Check if the last file has been created
datefinal = pd.Timestamp(da.S.values[-1])
yearfinal = str(datefinal.year)
monthfinal = str(datefinal.month).zfill(2)
dayfinal = str(datefinal.day).zfill(2)
ofinalname = yearfinal+monthfinal+dayfinal+'.e'+str(int(en))+'.y'+str(int(yv))+\
'.x'+str(int(xv))+'.nc'
if not os.path.isfile(outDir+ofinalname):
    # The server may time out so check what the last file was
    # created, delete it, and start it from there again
    filescreated = glob.glob(outDir+'*.e'+str(int(en))+'.y'+str(int(yv))+\
                             '.x'+str(int(xv))+'.nc')
    nfilescreated = len(filescreated)
    if nfilescreated != 0:
        filescreated.sort()
        os.unlink(filescreated[-1])
    else:
        nfilescreated = 1
    
    for ic in range(nfilescreated-1, len(da.S.values)):
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
        if len(remote_data.dims) == 6:
            try:
                da2 = da2.expand_dims('S').expand_dims('M').expand_dims('P').\
                      expand_dims('Y').expand_dims('X')
            except: IndexError
                exit('All data likely downloaded. You can check '+\
                      inFname[:-4]+'#views to see if it can generate an image.')
        else:
            try:
                da2 = da2.expand_dims('S').expand_dims('M').expand_dims('Y').\
                      expand_dims('X')
            except: IndexError
                exit('All data likely downloaded. You can check '+\
                      inFname[:-4]+'#views to see if it can generate an image.')            
        # Save file
        da2.to_netcdf(outDir+ofname)
