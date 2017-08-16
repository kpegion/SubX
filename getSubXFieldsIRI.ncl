;**************************************************************************************
;  getSubXFieldsIRI.ncl
;
;  Description:
;   Reads a field (lonxlat) for all lead times (nleads) from IRI SubX Database
;  
;  Output:
;   Files are of the form <varname>_<plev>_<group>-<model>_<yyyymmdd>.e<e>.daily.nc, where 
;   <yyyymmdd> - start date
;   <e> - ensemble member
;   <plev> - pressure level
;   The output file contains the specified variable for all lead times at a given level, for 
;   a given ensemble member and start date (i.e. data(nlon,nlat,nlead)) as well as the dimension
;   variables lon(nlon), lat(nlat), time(nlead).
;
;   The output directory that the file is placed in is:
;    <outPath>/<varname><plevstr>/daily/full/<group>-<model>, where
;    <outPath> - user specified
;    <varname> - user specified -- will be same as input varname
;    <plevstr> - pressure level (e.g. 200, 850, etc.)
;    /daily -- indicates daily data (weekly may also be an option eventually)     
;    /full/ -- indicates full fields (as opposed to anomalies)
;    <group> -- modeling group
;    <model> -- model name
;
;  !!!Important Note!!!!
;     This is a large dataset. Make sure that you have space to put the output files.  
;
;  History:
;
;  6/15/2017 Created Kathy Pegion 
;  8/16/2017 Modified for changes to dimensions in IRI Data Library Kathy Pegion 
;
;  Project Information:
;   This program was created as part of the Subseasonal Experiment (SubX), a project
;   funded by NOAA/MAPP, ONR, NWS/STI, and NASA/MAP.  Futher information on the SubX 
;   project can be found at http://cola.gmu.edu/kpegion/subx/
;
;**************************************************************************************

;---------------------------------------------------
;  User Defined Variables
;---------------------------------------------------
outPath="/data/scratch/kpegion/testSubX/ncl/"
varnames=(/"ua","ua","rlut","tas","ts","zg"/)
plevstrs=(/"850","200","toa","2m","sfc","500"/)
grps=(/"GMAO","RSMAS","ESRL","ECCC","NRL","EMC"/)
models=(/"GEOS_V2p1","CCSM4","FIMr1p1","GEM","NESM","GEFS"/)
dfv=-9.99e8
;---------------------------------------------------
; Variables - DO NOT MODIY
;---------------------------------------------------
url="http://iridl.ldeo.columbia.edu/SOURCES/.Models/.SubX/"

nvars=dimsizes(varnames)
nmodels=dimsizes(models)

;---------------------------------------------------
; Main Program
;---------------------------------------------------

do imodel=0,nmodels-1

   model=models(imodel)
   grp=grps(imodel)
 
   do ivar=0, nvars-1

      varname=varnames(ivar)
      plevstr=plevstrs(ivar)
  
      ; Define input filename
      fname=url+"."+grp+"/."+model+"/.hindcast/."+varname+"/dods"
 
      ; Open the file
      inFname=addfile(fname,"r")

      ;Get the dimensions
      dims=getfilevardims(inFname,varname)
      ndims=dimsizes(dims)

      ; Loop over the dimensions
      do i=0, ndims-1
         if (dims(i).eq."X") then
             lon=inFname->X
             nx=dimsizes(lon)
         else if (dims(i).eq."Y") then
             lat=inFname->Y
             ny=dimsizes(lat)
         else if (dims(i).eq."L") then
             leads=inFname->L
             nleads=dimsizes(leads)
         else if (dims(i).eq."M") then
             ens=inFname->M
             nens=dimsizes(ens)
         else if (dims(i).eq."S") then
             ics=inFname->S
             nics=dimsizes(ics)
         else if (dims(i).eq."P") then
             levs=inFname->P
             plev=ind(levs.eq.stringtointeger(plevstr))
         else 
          print("ERROR WITH DIMS: "+dims(i))
         end if
         end if
         end if
         end if
         end if
         end if
      end do ; ndims
      nics=1

      ; Create output directory
      outDir=outPath+varname+plevstr+"/daily/full/"+grp+"-"+model+"/" 
   
      ; Check to see if it exists
      tmp=systemfunc("mkdir -p "+outDir)

      ; Loop over all ensemble members
      do iens=0,nens-1

         ; Set ensemble string for output file name
         ee=sprinti("%0.1i",iens+1)

         ; Loop over and read all start dates
         do ic=0,nics-1
   
            ; Set date string to file name
            cdate=cd_calendar(ics(ic),0)
            year=tointeger(cdate(:,0))
            month=tointeger(cdate(:,1))
            day=tointeger(cdate(:,2))
            yyyymmdd=sprinti("%0.4i",year)+sprinti("%0.2i",month)+sprinti("%0.2i",day)
   
       
            ; Create output file name & remove if existing
            ofile=outDir+varname+"_"+plevstr+"_"+grp+"-"+model+"_"+yyyymmdd+".e"+ee+".daily.nc"
            if (fileexists(ofile)) then
               tmp=systemfunc("rm "+ofile)
            end if

            ; Open file
            oFname=addfile(ofile,"c")

            ; Get the data for dimensions lead,lat,lon
            if (ndims.eq.6) then
               ;data=inFname->$varname$(ic,plev,iens,:,:,:)
               data=inFname->$varname$(plev,iens,:,ic,:,:)
            else if (ndims.eq.5) then
               ;data=inFname->$varname$(ic,iens,:,:,:)
               data=inFname->$varname$(iens,:,ic,:,:)
            else
               print("Problems with dimensions")
            end if
            end if

            printVarSummary(data)

            ; Set the Global Attributes
            gAtt               = True 
            gAtt@long_title   = data@long_name
            gAtt@title         = data@long_name
            gAtt@comments   = "SubX project http://cola.gmu.edu/~kpegion/subx/"
            gAtt@CreationDate = systemfunc ("date")
            gAtt@CreatedBy = systemfunc ("whoami")
            gAtt@Source = "getSubXFieldsIRI.ncl"
            gAtt@Institution = "SubX IRI: "+url
            fileattdef( oFname, gAtt )

            ; Change dimension names to time, lat, lon
            data!0="time"
            data!1="lat"
            data!2="lon"
    
            ; Write the data to the file
            oFname->$varname$  = data
            oFname->$varname$@units=data@units
 
            ; Write the time units to the file
            oFname->time@units = ics@units

            ; Delete data so it can be defined automatically on next iteration
            delete(data)

         end do ;nics

      end do ;nens

      delete(dims)
      delete(ics)
      delete(lon)
      delete(lat)
      delete(leads)
      delete(ens)

      if (isdefined((/"levs"/))) then
        delete(levs)
      end if
   end do ;nvars

end do ;nmodels
