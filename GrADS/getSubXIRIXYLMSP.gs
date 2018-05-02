* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
* This GrADS script generates descriptor files for the
* SubX hindcast data behind the OPeNDAP server at IRI. 
* It can also open each descriptor file it creates and 
* write out the data locally as zipped netcdf. 
* 
* Written by Jennifer Adams, August 2017
* Modified for SubX github repository, Kathy Pegion,  8/17/2017
*
* Users will need to modify the following variables:
*   group - Specify the modeling group selected for data download
*   model - Specify the name of the model for data download
*   type - Specify hindcast or forecast
*   var - Specify the name of variable for data download
*   title - Specify the long name of the variable for data download
*   units - Specify the units of the data for download
*   hasP - Set to 1 if variable has a P coordinate (i.e. is multi-level data); set to 0 for no P coordinate
*   ctlpath - user defined path to place ctl files
*   datapath - user defined path to put downloaded data
*   ncdump - ncdump is required for this program to run; if not in PATH, specify path for ncdump here
*   writedata - set to 0 to only create .ctl files; set to 1 to create .ctl files and write data    
*
* External Codes Required
*    isfile.sh should be placed in the same directory; Users should confirm that is has execute permissions
*
* Notes:
*    Data output from this program will have dimensions of lon,lat,time,level,ens which map to GrADS dimensions
*    x,y,t,z,e
*    In the output files, Time refers to lead-time.  
*
*  !!!Important Note!!!!
*     This is a large dataset. Make sure that you have space to put the output files.  
*
*  SubX Project Information:
*   The Subseasonal Experiment (SubX) is a project
*   funded by NOAA/MAPP, ONR, NWS/STI, and NASA/MAP.  Futher information on the SubX 
*   project can be found at http://cola.gmu.edu/kpegion/subx/
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
function main()
'reinit'

* Set Group ,Model, type of data
group='GMAO'
model='GEOS_V2p1'
type='hindcast'

* Set variable metadata 
var='ua'
title='zonal velocity'
units='m/s'
hasP=1 ;* set this to 1 if variable has a P coordinate 

* Some local system variables
ctlpath='/scratch/kpegion/testSubX/swapdim/GrADS/ctl'
datapath='/scratch/kpegion/testSubX/swapdim/GrADS'
_ncdump='ncdump'
* Set this to 0 to just create the descriptor files
* Set this to 1 to create the descriptor files and write out the data locally
writedata=1


* This is where the data are hosted
_URL='http://iridl.ldeo.columbia.edu/SOURCES/.Models/.SubX/'group'/'model'/.'type'/.'var'/dods'

* Use ncdump to get the missing value
cmd=_ncdump' -h '_URL' | grep 'var':missing_value'
rex = sys(cmd); undef=subwrd(rex,3)
len=math_strlen(undef);
if (len=0)
  undef='-9.99e8'
else
  len=len-1 ; undef=substr(undef,1,len)
  if (undef='NaN'); undef='-9.99e8'; endif
endif

* Get the L dimension size
cmd=_ncdump' -h '_URL' | grep "L = "'
rex = sys(cmd)
Lsize=subwrd(rex,3)

* Get the M dimension size
cmd=_ncdump' -h '_URL' | grep "M = "'
rex = sys(cmd)
Msize=subwrd(rex,3)

* Get the P dimension size if there is a Z axis
if (hasP)
  cmd=_ncdump' -c '_URL' | grep "P = "'
  rex=sys(cmd); rex1=sublin(rex,1); rex2=sublin(rex,2)
  Zsize=subwrd(rex1,3)
  zdef='zdef 'Zsize' levels'
  lev=1
  w=3
  while (lev<=Zsize)
    word=subwrd(rex2,w)
*   remove the trailing comma
    len=math_strlen(word); len=len-1
    pval=substr(word,1,len)
    zdef=zdef' 'pval
    lev=lev+1
    w=w+1
  endwhile
else
  zdef='zdef 1 linear 0 1'
endif

* Get the S dimension size and the initial value
cmd=_ncdump' -c '_URL' | grep "S = "'
rex=sys(cmd); rex1=sublin(rex,1); rex2=sublin(rex,2)
Ssize=subwrd(rex1,3)
Sinit=subwrd(rex2,3); len=math_strlen(Sinit); len=len-1 ; Sinit=substr(Sinit,1,len)

* Set up a dummy descriptor with a daily time axis
_dummy='./dummy_'var'.ctl'
rc = create_dummy_ctl(var)
if (rc)
  say 'Something went wrong creating '_dummy
  return
endif
'open '_dummy
if (rc)
  say 'Unable to open '_dummy
  return
endif

* Loop over initialization times
* s is the index for the S coordinate variable
* t = S[s], and is used to figure out the date
s=1
t=Sinit
while (s<=Ssize)
  'set t 't+1
  'q time'
  time=subwrd(result,3)
  day=substr(time,4,2)
  mon=substr(time,6,3)
  year=substr(time,9,4)
  mm=getmm(mon)

* Create a local descriptor with a DSET entry pointing to the URL
  '!mkdir -p 'ctlpath'/'var
  ctl=ctlpath'/'var'/'var'_'year%mm%day'.ctl'
  dset='dset '_URL
  rc=write(ctl,dset)
  desc='title SubX Hindcasts 'title' Initialized 'time
  rc=write(ctl,desc,append)
  rc=write(ctl,'dtype netcdf',append)
  missing='undef 'undef
  rc=write(ctl,missing,append)
  rc=write(ctl,'xdef 360 linear   0 1',append)
  rc=write(ctl,'ydef 181 linear -90 1',append)
  rc=write(ctl,zdef,append)
  tdef='tdef 'Lsize' linear 'time' 1dy'
  rc=write(ctl,tdef,append)
  edef='edef 'Msize' names'
  e=1
  while (e<=Msize)
    edef=edef%' 'e
    e=e+1
  endwhile
  rc=write(ctl,edef,append)
  rc=write(ctl,'vars 1',append)
  if (hasP)
    vardec=var' 'Zsize' z,'s-1',e,t,y,x 'title' 'units
  else
    vardec=var' 0 's-1',e,t,y,x 'title' 'units
  endif
  rc=write(ctl,vardec,append)
  rc=write(ctl,"endvars",append)
  rc=close(ctl)

  if (writedata)
*   Write out the data to local netcdf file
    outdir=datapath'/'type'/'var'/daily/full/'group'-'model'/'
    '!mkdir -p 'outdir
    outfile=outdir'/'var'_'group'-'model'_'year%mm%day'.daily.nc'
*   Check if outfile already exits
    got=isfile(outfile)
    if (got=1)
      say outfile' exists'
    else
      say 'CREATING 'outfile
*     open the descriptor file we just created
      'open 'ctl
      line2=sublin(result,2)
      filenum=subwrd(line2,8)
      'set dfile 'filenum
      'q file'
      file=sublin(result,3)
      url=subwrd(file,2)
      lims=sublin(result,5)
      xsiz=subwrd(lims,3)
      ysiz=subwrd(lims,6)
      zsiz=subwrd(lims,9)
      tsiz=subwrd(lims,12)
      esiz=subwrd(lims,15)
      'set x 1 'xsiz
      'set y 1 'ysiz
      'set z 1 'zsiz
      'set t 1 'tsiz
      'set e 1 'esiz
      'define 'var'='var
      bytes=subwrd(result,6)
      'clear sdfwrite'
      'set sdfwrite -flt -nc4 -zip 'outfile
      'set sdfattr global String Source 'url
      'set sdfattr 'var' String long_name 'title
      'set sdfattr 'var' String units 'units
      'sdfwrite 'var
      say result
      'undefine 'var
      'close 'filenum
    endif
  endif
  s=s+1
  t=t+7
endwhile
'close 1'

* * * End of Main Script * * *
function create_dummy_ctl(var)
* Get the time axis unit from the url
cmd=_ncdump' -h '_URL' | grep "S:units"'
rex=sys(cmd)
* rex should look like this ==>     S:units = "days since 1960-01-01" ;
unit=subwrd(rex,3)
start=subwrd(rex,5)
if (unit='"days')
  incr='1dy'
else
  say 'Something is wrong with S axis units: 'rex
  return 1
endif
yr=substr(start,1,4)
mm=substr(start,6,2)
dd=substr(start,9,2)
mons='jan feb mar apr may jun jul aug sep oct nov dec'
mon=subwrd(mons,mm)
tdef='tdef 10 linear 'dd%mon%yr' 'incr
* now write it out
rc=write(_dummy,"dset ^foo")
rc=write(_dummy,"options template",append)
rc=write(_dummy,"undef -9.9e8",append)
rc=write(_dummy,"xdef 1 linear 1 1",append)
rc=write(_dummy,"ydef 1 linear 1 1",append)
rc=write(_dummy,"zdef 1 linear 1 1",append)
rc=write(_dummy,tdef,append)
rc=write(_dummy,"vars 1",append)
rc=write(_dummy,"foo 0 99 foo",append)
rc=write(_dummy,"endvars",append)
rc=close(_dummy)
return 0


function getmm(mon)
if (mon='JAN'); mm='01'; endif
if (mon='FEB'); mm='02'; endif
if (mon='MAR'); mm='03'; endif
if (mon='APR'); mm='04'; endif
if (mon='MAY'); mm='05'; endif
if (mon='JUN'); mm='06'; endif
if (mon='JUL'); mm='07'; endif
if (mon='AUG'); mm='08'; endif
if (mon='SEP'); mm='09'; endif
if (mon='OCT'); mm='10'; endif
if (mon='NOV'); mm='11'; endif
if (mon='DEC'); mm='12'; endif
return mm
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* function isfile(file)
* Determines whether the named file exists
*
function isfile(file)
cmd='isfile.sh 'file
res=sys(cmd)
got=subwrd(res,1)
return got
