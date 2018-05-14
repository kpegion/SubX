""" Download SubX data from IRI.

Creates folders in the form [hindcast/forecast]/model/var/pvel/ and outputs 
files YYYMMDD.eN.nc

Change L34-L44 to download the data of your choice.

See https://sites.google.com/view/raybellwaves/pythonrsmas
for notes on installing python.

To setup the environment and run this script:
    $ git clone https://github.com/kpegion/SubX.git
    $ cd SubX/Python
    $ conda env create -f requirements-py36.yml
    $ conda activate SubXdata
    $ python getSubXFieldsIRI.py
    
History: 5/14/18 Created by Ray Bell and adapted from getFieldsIRIXYLMSP.py

Project Information:
    This program was created as part of the Subseasonal Experiment (SubX),
    a project funded by NOAA/MAPP, ONR, NWS/STI, and NASA/MAP. Futher 
    information on the SubX  project can be found at 
    http://cola.gmu.edu/kpegion/subx/
"""
import os
import glob
from subprocess import call
from netCDF4 import Dataset
from cftime import num2date, date2num
import numpy as np
from datetime import datetime, timedelta

# user defined variables. Options are showns after the #:
# -------------------------------------------------------
outPath='/Volumes/SAMSUNG/WORK/POSTDOC_RSMAS_2016/DATA/SubX/'
ftype='hindcast' # hindcast, forecast
models = ['CCSM4'] # 30LCESM1, 46LCESM1, CCSM4, CFSv2, FIMr1p1, GEFS, GEM,
# GEOS_V2p1, NESM
# See http://iridl.ldeo.columbia.edu/SOURCES/.Models/.SubX/ for a list of
# models availiible
varnames = ['zg'] # pr, tas, ts, rlut, ua, va, zg.
# See http://cola.gmu.edu/kpegion/subx/data/priority1.html or
# http://cola.gmu.edu/kpegion/subx/data/priority2.html for a list of 
# abbreviations.
plevs = ['500'] # 200, 500, 850, 2m, sfc, toa
# See http://cola.gmu.edu/kpegion/subx/docs/SubXDataQuickReferenceGuide.pdf
# for notes on what presseure level is associated with the data
# -------------------------------------------------------

# Error checks on user input
if outPath is '/place/with/lots/of/storage/':
    raise ValueError('Change outPath from default on LX.')
if len(varnames) != len(plevs):
    raise ValueError('varnames and plevs must be same length. If variable '+\
                     'doesn"/t have a plev use a placeholder such as None.')    

url='http://iridl.ldeo.columbia.edu/SOURCES/.Models/.SubX/'
dfv=-9.99e-8 # Default missing_value or FillValue if not specified in input

             
# Functions
def mod_ins(model):
    """Get the institute the model is associated with.
    
    Parameters
    ----------
    model : list
        Name of model.
    
    Retuns
    ------
    out : str
        Model instituion
    """
    int_dict = {'30LCESM1': "CESM",
                '46LCESM1': "CESM",
                'CCSM4': "RSMAS",
                'CFSv2': "NCEP",
                'FIMr1p1': "ESRL",
                'GEFS': "EMC",
                'GEM': "ECCC"}
    return int_dict[model]            


# Main code
for i, model in enumerate(models):
    institute = mod_ins(model)
    
    for j, var in enumerate(varnames):
        plevstr = plevs[j]
        
        inFname = '%s.%s/.%s/.hindcast/.%s/dods' % (url,institute,model,var)

        # Open netcdf File
        ncfile = Dataset(inFname, 'r')
        
        # Determine number of dimensions
        ndims = len(ncfile.dimensions)
        
        # Get dimensions names
        ncdims = [dim for dim in ncfile.dimensions]
        # ~(L, M, P, S, X, Y)
        
        # Read Dimension variables
        for k, dim in enumerate(ncdims):
            if dim == 'L':
                # Lead time
                leads = ncfile.variables['L']
                unitsl = ncfile.variables['L'].units
                leadsvals = leads[:]               
                nleads = len(leadsvals)                
                leadatts = ncfile.variables['L'].ncattrs()
            elif dim == 'M':
                # Ensemble member
                ens = ncfile.variables['M'][:]
                nens = len(ens)
            elif dim == 'P':
                # Pressure level
                levs = np.array(ncfile.variables['P'][:])
                plev = np.where(levs==float(plevstr))[0]
            elif dim == 'S':
                # Start date
                ics = ncfile.variables['S'][:]
                nics = len(ics)
                unitst = ncfile.variables['S'].units
                try:
                    tcal = ncfile.variables['S'].calendar
                except AttributeError :
                    # Attribute doesn't exist
                    tcal = "standard"            
                # Convert number to date
                datevar = num2date(ics, units = unitst, calendar = tcal)
            elif dim == 'X':
                # Longitude
                lon = ncfile.variables['X']
                lonvals = lon[:]
                lonatts = ncfile.variables['X'].ncattrs()
                nx = len(lonvals)                
            elif dim == 'Y':
                # Latitude
                lat = ncfile.variables['Y']
                latvals = lat[:]
                latatts = ncfile.variables['Y'].ncattrs()
                ny = len(latvals)
            else:
                raise NameError('Unexpected Dimensions : ',dim)
        
        # Create output directory if doesn't exist
        outDir = '%s%s/%s/%s/%s/daily/' % (outPath,ftype,model,var,plevstr)
        if not os.path.isdir(outDir):
            os.makedirs(outDir)
            
        for iens in range(nens):
            ee = int(iens) + 1
            
            # This script occassionaly crashes so check what the last file was
            # created, delete it and start it from there again
            filescreated = glob.glob(outDir+'*e'+str(ee)+'*')
            nfilescreated = len(filescreated)
            filescreated.sort()
            os.unlink(filescreated[-1])
            
            for ic in range(nfilescreated-1, nics):              
                # Construct date string for this initial condition
                yyyymmdd='%s%s%s' % (datevar[ic].strftime('%Y'),\
                                     datevar[ic].strftime('%m'),\
                                     datevar[ic].strftime('%d'))
                
                # Uodate dates as start date + lead time
                dates = [None] * nleads
                if unitsl == 'days':
                    for n in range(nleads):
                        dates[n] = datevar[ic]+\
                        timedelta(days=float(leadsvals[n]))
                else:
                    raise NotImplementedError('Only implemented lead time of \
                                              days.')
                datesnum = date2num(dates, units=unitst, calendar=tcal)
                
                # Get the data based on the number of dimensions
                if ndims == 6:
                    # (P, I, M, L, Y, X)
                    data = ncfile.variables[var][plev,ic,iens,:,:,:].squeeze()
                elif ndims == 5:
                    # (I, M, L, Y, X)
                    data = ncfile.variables[var][ic,iens,:,:,:].squeeze()
                else:
                    raise ValueError('Variable should have 5 or 6 dims.')
                    
                # Outfile name
                ofname = '%s.e%s.nc' % (yyyymmdd,ee)
                rootgrp = Dataset(outDir+ofname, 'w', FORMAT="NETCDF4")
            
                # Create dimensions
                rootgrp.createDimension('time',nleads)
                rootgrp.createDimension('lat',ny)                
                rootgrp.createDimension('lon',nx)
            
                # Create variables
                times = rootgrp.createVariable('time',leads.dtype.char,
                                           ('time'))
                lats = rootgrp.createVariable('lat',lat.dtype.char,('lat'))
                lons = rootgrp.createVariable('lon',lat.dtype.char,('lon'))
                datas = rootgrp.createVariable(var,data.dtype.char,
                                               ('time','lat','lon'))
            
                # Write data
                times[:] = datesnum
                lats[:] = latvals
                lons[:] = lonvals
                datas[:] = data
            
                # Set Variable Attributes
                for attr in leadatts:
                    times.setncattr(attr,leads.getncattr(attr))
                    times.setncattr('units',unitst)
                for attr in latatts:                    
                    lats.setncattr(attr,lat.getncattr(attr))
                for attr in lonatts:
                    lons.setncattr(attr,lon.getncattr(attr))
                for attr in ncfile.variables[var].ncattrs():
                    datas.setncattr(attr,
                                    ncfile.variables[var].getncattr(attr))
                
                # Set fillValue
                try:
                    datas.setncattr('fillValue',ncfile.variables[var].\
                                    getncattr('fillValue'))
                except:
                    try:
                        datas.setncattr('fillValue',ncfile.variables[var].\
                                        getncattr('missing_value'))
                    except:
                        datas.setncattr('fillValue',dfv)
                    
                # Set Global Attributes for Output
                now=datetime.now()
                rootgrp.long_title=ncfile.variables[var].\
                getncattr('long_name')
                rootgrp.title=ncfile.variables[var].\
                getncattr('long_name')
                rootgrp.comments='SubX project'+\
                'http://cola.gmu.edu/~kpegion/subx/'
                rootgrp.CreationDate=now.strftime("%Y-%m-%d %H:%M")
                rootgrp.CreatedBy=os.getlogin()
                rootgrp.Source='https://github.com/kpegion/SubX/tree/'+\
                'master/Python/getSubXdata.py'
                rootgrp.Institution='SubX IRI%s' % (url)

                # Close output file
                rootgrp.close()
                
        # Close input file   
        ncfile.close()
