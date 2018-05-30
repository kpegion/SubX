# SubX Codes

This repository contains codes for accessing and processing SubX data in various languages/environments, including Matlab, NCL, Python and GrADS.

# Matlab

V1/ - version 1, Matlab code for getting the SubX data from the IRI Data Library, 
 getSubXFieldsIRI.m -- A sample matlab program for getting SubX 2-D Fields
    
V2/ - version 2, consists of getSubXFieldsIRI.m and additional programs for processing the SubX data into ensemble means, calculating climatologies, and calculating anomalies of the ensemble means.
Important Note: Before Apr 10, 2018, use getSubXFieldsIRI.m to download data
                Starting Apr 10, 2018, use getSubXFieldsIRIXYLMSP.m to download data
  
 # NCL

  getSubXFieldsIRI.ncl -- A sample ncl program for getting SubX 2-D fields
  
  Modify variables at top listed as User Defined Variables

  No external Codes
  
  Important Note: Before Apr 10, 2018, use getSubXFieldsIRI.ncl to download data
                Starting Apr 10, 2018, use getSubXFieldsIRIXYLMSP.ncl to download data
  
# Python
  
Markup : * `Python/download_data/generate_full_py_ens_files.ksh` creates python files to download each ensemble member for a chosen model etc. These can then be run in parallel. 
         * `Python/download_data/generate_ts_py_ens_files.ksh` creates python files to download each ensemble member for a chosen model etc. at one location. These can then be run in parallel. 
         * `Python/create_climatology/generate_ts_clim.ksh` creates a python file to create a daily climatology of the SubX data for a single point. 
  
# GrADS
  
    getSubXIRI.gs -- A sample program for getting SubX data.
    
    Important Note: Before Apr 10, 2018, use getSubXFieldsIRI.gs to download data
                Starting Apr 10, 2018, use getSubXFieldsIRIXYLMSP.gs to download data

Note that the output files in this case will contain all ensemble members and levels as opposed to the other codes which write the ensemble members and levels as separate files.  These output files will NOT work properly with the Matlab data processing codes above because they produce files in a different format. 

Mapping the dimensions appropriately in GrADS across the IRI OpenDAP server can be challenging.  Jennifer Adams (COLA/GMU) has provided the following information to assist GrADS users in understanding how this works..

Here is an example SubX URL for 2-meter air temperature: 

http://iridl.ldeo.columbia.edu/SOURCES/.Models/.SubX/.ESRL/.FIMr1p1/.hindcast/.tas/

It has five dimensions:

float tas(M, L, S, Y, X) ;

Two of these coordinates are time-related — L for lead time or forecast period and S for reference (initialization) time. GrADS can only support one time axis, so one of these has to be ‘mapped' to a different coordinate in the 5D GrADS environment. M maps naturally to the E dimension, X is Latitude, Y is Longitude, and so that leaves Z available for the L dimension and T is used for the reference time or start time of an individual foreast. This way, the 4D grid at each fixed time step is an individual forecast, with Z=1 as the initial time and Z=32 is a 32-day forecast. The T axis in GrADS increments every 7 days, as each new forecast is initialized once a week.

The GrADS descriptor for this mapping (MLSYX --> EZTYX) looks like this:

dset http://iridl.ldeo.columbia.edu/SOURCES/.Models/.SubX/.ESRL/.FIMr1p1/.hindcast/.tas/

dtype netcdf

title SubX ESRL Hindcasts 2-meter Temperature

undef -9.99e8

xdef 360 linear   0 1

ydef 181 linear -90 1

zdef 32 linear 0 1

tdef 835 linear 06jan1999 7dy

edef 4 names 1 2 3 4

vars 1

tas 32 e,z,t,y,x  2-meter Temperature [K]

endvars

An advantage to this approach is that all the grids for a single variable can be encapsulated into one descriptor, and it can be easy to do averages or other calculations over the Z, T, or E axis. The disadvantage is that time metadata is lost for the forecasts, only the initialization grids (when z=1) will actually have a meaningful time stamp. If you want to compare the data to another model or reanalysis, you have to be very careful and deliberate about keeping track of the the dimension environment and calculating a valid time (or verification time) for each step in the Z dimension. This is especially tricky because the increment between t=1 and t=2 is seven days, and the increment between z=1 and z=2 is one day.

Another disadvantage to this approach arises if the variable in question already has a Z dimension — an example is air temperature at several pressure levels:

http://iridl.ldeo.columbia.edu/SOURCES/.Models/.SubX/.ESRL/.FIMr1p1/.hindcast/.ta/

where the variable ‘ta’ has six dimensions:

float ta(P, M, L, S, Y, X) ;

The solution is to create four variables in the descriptor, one for each pressure level, and numerical indices are added to the letters in the variable declarations to indicate a fixed array index for that particular coordinate — see Usage Note #4 in http://cola.gmu.edu/grads/gadoc/SDFdescriptorfile.html for more information.

A slighly more cumbersome but less error-prone mapping is to create one descriptor file for each forecast. This strategy will create N descriptor files, where N is the size of the S dimension, but each grid in the entire collection will have properly registed time metadata and can easily be compared to another data set. The mapping is MLSYX—>ETnYX, when n is an integer that varies between 0 and S-1.

Here are examples of what the first and final descriptor files in the collection would look like (note the integers in the variable declarations and the different intial time values):

dset http://iridl.ldeo.columbia.edu/SOURCES/.Models/.SubX/.ESRL/.FIMr1p1/.hindcast/.tas/dods

title SubX Hindcasts 2-meter Temperature Initialized 00Z06JAN1999

dtype netcdf

undef -9.99e8

xdef 360 linear   0 1

ydef 181 linear -90 1

zdef 1 linear 0 1

tdef 32 linear 00Z06JAN1999 1dy

edef 4 names 1 2 3 4

vars 1

tas 0 e,t,0,y,x 2-meter Temperature K

endvars

dset http://iridl.ldeo.columbia.edu/SOURCES/.Models/.SubX/.ESRL/.FIMr1p1/.hindcast/.tas/dods

title SubX Hindcasts 2-meter Temperature Initialized 00Z31DEC2014

dtype netcdf

undef -9.99e8

xdef 360 linear   0 1

ydef 181 linear -90 1

zdef 1 linear 0 1

tdef 32 linear 00Z31DEC2014 1dy

edef 4 names 1 2 3 4

vars 1

tas 0 e,t,834,y,x 2-meter Temperature [K]

endvars

For the case of the variable with a pressure coordinate, the mapping is PMLSYX—>ZETnYX, when n is an integer that varies between 0 and S-1. Now P and L are both mapped to their proper world coordinates Z and T:

dset http://iridl.ldeo.columbia.edu/SOURCES/.Models/.SubX/.ESRL/.FIMr1p1/.hindcast/.ta/dods

title SubX Hindcasts Air Temperature Initialized 00Z31DEC2014

dtype netcdf

undef -9.99e8

xdef 360 linear   0 1

ydef 181 linear -90 1

zdef 4 levels 100 50 30 10

tdef 32 linear 00Z31DEC2014 1dy

edef 4 names 1 2 3 4

vars 1

ta 4 z,e,t,834,y,x Air Temperature [K]

endvars


All of the above examples use URLs as DSET entries. They rely on the OPeNDAP capability in the GrADS build to handle the data I/O. This can be very convenient because the user can work with the data remotely, without having to download any files. The disadvantage is that it may be slow and inefficient for some calculations. It is usually worth the trouble to download it to a local disk. The GrADS script provided here creates descriptor files that point to the URLs, then uses those to write out each forecast in a single compressed netcdf file.

The example given is for the 2-meter air temperature, but for other variables it is only necessary to edit a few lines at the top to change the metadata.
  
