""" Download SubX data from IRI.

Template file to be used with generate_full_py_ens_files.ksh
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
en = ens.0

inFname = rl+'.'+ins+'/.'+mo+'/.'+ft+'/.'+va+'/dods'
remote_data = xr.open_dataarray(inFname)
if len(remote_data.dims) == 6:
    da = remote_data.sel(P=plev)
if len(remote_data.dims) == 5:
    da = remote_data
    
outDir = outPath+ft+'/'+mo+'/'+va+'/'+str(pl)+'/daily/full/'
if not os.path.isdir(outDir):
    os.makedirs(outDir)
    
# Check if the last file has been created
datefinal = pd.Timestamp(remote_data.S.values[-1])
yearfinal = str(datefinal.year)
monthfinal = str(datefinal.month).zfill(2)
dayfinal = str(datefinal.day).zfill(2)
ofname = yearfinal+monthfinal+dayfinal+'.e'+str(int(en))+'.nc'
if not os.path.isfile(outDir+ofname):
    # The server may time out so check what the last file was
    # created, delete it, and start it from there again
    filescreated = glob.glob(outDir+'*e'+str(int(en))+'*.nc')
    nfilescreated = len(filescreated)
    if nfilescreated != 0:
        filescreated.sort()
        os.unlink(filescreated[-1])
    else:
        nfilescreated = 1
    
    for ic in range(nfilescreated-1, len(remote_data.S.values)):
        # Convert to a pandas.Timestamp to get year, month, data
        date = pd.Timestamp(remote_data.S.values[ic])
        year = str(date.year)
        # Use zfill to pad with 0
        month = str(date.month).zfill(2)
        day = str(date.day).zfill(2)
                    
        # Out file name
        ofname = year+month+day+'.e'+str(int(en))+'.nc'
        
        # Select the 2D filed and keep the other dimensions
        da2 = da.sel(M=en, S=remote_data.S.values[ic])
        if len(remote_data.dims) == 6:
            da2 = da2.expand_dims('S').expand_dims('M').expand_dims('P')
        else:
            da2 = da2.expand_dims('S').expand_dims('M')
            
        # Save file
        da2.to_netcdf(outDir+ofname)