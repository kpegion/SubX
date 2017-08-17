#!/usr/bin/python

#**************************************************************************************
#  getSubXFieldsIRI.py
#
#  Description:
#   Reads a field (lonxlat) for all lead times (nleads) from IRI SubX Database
#  
#  Output:
#   Files are of the form <varname>_<plev>_<group>-<model>_<yyyymmdd>.e<e>.daily.nc, where 
#   <yyyymmdd> - start date
#   <e> - ensemble member
#   <plev> - pressure level
#   The output file contains the specified variable for all lead times at a given level, for 
#   a given ensemble member and start date (i.e. data(nlon,nlat,nlead)) as well as the dimension
#   variables lon(nlon), lat(nlat), time(nlead).
#
#   The output directory that the file is placed in is:
#    <outPath>/<varname><plevstr>/daily/full/<group>-<model>, where
#    <outPath> - user specified
#    <varname> - user specified -- will be same as input varname
#    <plevstr> - pressure level (e.g. 200, 850, etc.)
#    /daily -- indicates daily data (weekly may also be an option eventually)     
#    /full/ -- indicates full fields (as opposed to anomalies)
#    <group> -- modeling group
#    <model> -- model name
#
#  !!!Important Note!!!!
#     This is a large dataset. Make sure that you have space to put the output files.  
#
#  History:
#
#  6/15/2017 Created Kathy Pegion 
#
#  Project Information:
#   This program was created as part of the Subseasonal Experiment (SubX), a project
#   funded by NOAA/MAPP, ONR, NWS/STI, and NASA/MAP.  Futher information on the SubX 
#   project can be found at http://cola.gmu.edu/kpegion/subx/
#
#**************************************************************************************

import os
from netCDF4 import Dataset, netcdftime, num2date
import numpy as np
import datetime

#------------------------------------------------
#  Variables to be modified by user
#------------------------------------------------
outPath='/data/scratch/kpegion/testSubX/python/'               # User output directory
varnames=['ua','ua','rlut','tas','ts','zg']                    # Variable names
plevstrs=['850','200','toa','2m','sfc','500']                  # Must be same size as varname; for variables with no plevels, use sfc or 10m
groups=['GMAO','RSMAS','ESRL','ECCC','NRL','EMC']              # Modeling Groups (must be same # elements as models below)
models=['GEOS_V2p1','CCSM4','FIMr1p1','GEM','NESM','GEFS']     # Model Name (must be same # of elements as groups above)
dfv=-9.99e-8;                                                  # Default missing_value or FillValue if not specified in input data file

#------------------------------------------------
#  Variables DO NOT MODIFY
#------------------------------------------------
url='http://iridl.ldeo.columbia.edu/SOURCES/.Models/.SubX/'
nvars=len(varnames)
nmodels=len(models)

#-------------------------------------------------
#  Main Program
#-------------------------------------------------
for ivar in range(nvars):

   varname=varnames[ivar]
   plevstr=plevstrs[ivar]
   
    
   for imodel in range(nmodels):

      model=models[imodel]
      group=groups[imodel] 

      # Create Filename
      inFname='%s.%s/.%s/.hindcast/.%s/dods' % (url,group,model,varname)

      # Open netcdf File
      ncfile = Dataset(inFname, 'r')

      # Determine number of dimensions
      ndims=len(ncfile.dimensions)

      # Get dimensions names
      ncdims = [dim for dim in ncfile.dimensions]
 
      # Read Dimension Variables
      for dim in ncdims:

         if dim=='Y':
            lat = ncfile.variables['Y']
            latvals = lat[:]
            latatts=ncfile.variables['Y'].ncattrs()
            ny=len(latvals)
         elif dim=='X':
            lon = ncfile.variables['X']
            lonvals = lon[:]
            lonatts=ncfile.variables['X'].ncattrs()
            nx=len(lonvals)
         elif dim=='L':
            leads = ncfile.variables['L']
            leadsvals=leads[:]
            leadatts=ncfile.variables['L'].ncattrs()
            nleads=len(leadsvals)
         elif dim=='M':
            ens = ncfile.variables['M'][:]
            nens=len(ens)
         elif dim=='S':
            ics = ncfile.variables['S'][:]
            nics=len(ics)
            unitst = ncfile.variables['S'].units
            try:
               tcal = ncfile.variables['S'].calendar
            except AttributeError : # Attribute doesn't exist
               tcal = u"standard"

            # Convert netcdf to datetime
            datevar=num2date(ics,units = unitst,calendar = tcal)

         elif dim=='P':
            levs = np.array(ncfile.variables['P'][:])
            plev=np.where(levs==float(plevstr))[0]
         else:
          print("Unexpected Dimensions : ",dim,"...Exiting")
          exit()

      # Create output directory if needed
      outDir='%s%s%s/daily/full/%s-%s/' % (outPath,varname,plevstr,group,model)
      directory=os.path.dirname(outDir)
      try:
         os.stat(directory)
      except:
         os.makedirs(directory)

   
      # Loop over all ensemble members
      for iens in range(nens):

         ee='%s' % (iens+1)
 
         # Loop over all starts
         nics=1
         for ic in range(nics):
           
           # Construct date string for this initial conditions
           yyyymmdd='%s%s%s' % (datevar[ic].strftime('%Y'),datevar[ic].strftime('%2m'),datevar[ic].strftime('%2d'))

           # Get the data based on number of dimensions
           if ndims==6:
              #data = ncfile.variables[varname][ic,plev,iens,:,:,:]
              data = ncfile.variables[varname][plev,iens,:,ic,:,:]
           elif ndims==5:
              #data = ncfile.variables[varname][ic,iens,:,:,:]
              data = ncfile.variables[varname][iens,:,ic,:,:]
           else: 
              print("Variables must have 5 [nens,nleads,nics,nlons,nlats] or 6 [nlevs,nens,nleads,nics,nlons,nlats]  dimensions...Exiting")
              exit()
  
           # Construct output filename & open output file
           ofname='%s%s_%s_%s-%s_%s.e%s.daily.nc' % (outDir,varname,plevstr,group,model,yyyymmdd,ee)
           ncout=Dataset(ofname,'w')

           # Write netCDF4 file for the field data[nleads,nlons,nlats]
           ncout.createDimension('lon',nx) 
           ncout.createDimension('lat',ny) 
           ncout.createDimension('time',nleads)
      
           tmplon = ncout.createVariable('lon',lon.dtype.char,('lon')) 
           tmplat = ncout.createVariable('lat',lat.dtype.char,('lat')) 
           tmptime = ncout.createVariable('time',leads.dtype.char,('time')) 
           tmpdata = ncout.createVariable(varname,data.dtype.char,('time','lat','lon')) 

           tmplon[:]=lonvals
           tmplat[:]=latvals
           tmptime[:]=leadsvals
           tmpdata[:]=data

           # Set Variable Attributes for Output
           for attr in latatts:
              tmplat.setncattr(attr,lat.getncattr(attr))
           for attr in lonatts:
              tmplon.setncattr(attr,lon.getncattr(attr))
           for attr in leadatts:
              tmptime.setncattr(attr,leads.getncattr(attr))
              tmptime.setncattr('units',unitst)
           for attr in ncfile.variables[varname].ncattrs():
              tmpdata.setncattr(attr,ncfile.variables[varname].getncattr(attr))

           # Set Global Attributes for Output
           now=datetime.datetime.now()
           ncout.long_title=ncfile.variables[varname].getncattr('long_name')
           ncout.title=ncfile.variables[varname].getncattr('long_name')
           ncout.comments='SubX project http://cola.gmu.edu/~kpegion/subx/'
           ncout.CreationDate=now.strftime("%Y-%m-%d %H:%M")
           ncout.CreatedBy=os.getlogin()
           ncout.Source='getSubXFieldsIRI.py'
           ncout.Institution='SubX IRI%s' % (url)
       
           # Close output file
           ncout.close()    
   
   # Close input file   
   ncfile.close()
