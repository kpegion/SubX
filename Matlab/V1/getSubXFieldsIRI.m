clear
%**************************************************************************************
%  getSubXFieldsIRI.m
%
%  Description:
%   Reads a field (lonxlat) for all lead times (nleads) from IRI SubX Database
%  
%  External Functions/Subroutines:
%     nctime2datestrdaily.m   
%     setupNetCDF3D.m
%     writeNetCDFGlobalAtts.m
%     writeNetCDFData3D.m
%     getFillValue.m
%
%  Output:
%   Files are of the form <varname>_<plev>_<group>-<model>_<yyyymmdd>.e<e>.daily.nc, where 
%   <yyyymmdd> - start date
%   <e> - ensemble member
%   <plev> - level (e.g. 500 for 500 hPa, sfc for surface, 10m for 10-meter, toa for top of atmosphere)
%   The output file contains the specified variable for all lead times at a given level, for 
%   a given ensemble member and start date (i.e. data(nlon,nlat,nlead)) as well as the dimension
%   variables lon(nlon), lat(nlat), time(nlead).
%
%   The output directory that the file is placed in is:
%    <outPath>/<varname><plevstr>/daily/full/<group>-<model>, where
%    <outPath> - user specified
%    <varname> - user specified -- will be same as input varname
%    <plevstr> - pressure level (e.g. 200, 500, 850 for hPa, sfc for surface, or 10m for 10-meter,)
%    /daily -- indicates daily data (weekly may also be an option eventually)     
%    /full/ -- indicates full fields (as opposed to anomalies)
%    <group> -- modeling group
%    <model> -- model name
%
%  !!!Important Note!!!!
%     This is a large dataset. Make sure that you have space to put the output files.  
%
%  History:
%
%  6/7/2017 Created Kathy Pegion 
%  8/14/2017 Modified for all models and updated dimensions order Kathy Pegion
%
%  Project Information:
%   This program was created as part of the Subseasonal Experiment (SubX), a project
%   funded by NOAA/MAPP, ONR, NWS/STI, and NASA/MAP.  Futher information on the SubX 
%   project can be found at http://cola.gmu.edu/kpegion/subx/
%
%**************************************************************************************


%--------------------------------------------------------------------------------------
% Variables to be modified by user
%--------------------------------------------------------------------------------------

outPath='/shared/ccsm4/subx/';					% User output directory
varnames={'ua';'ua';'rlut';'tas';'ts';'zg'}; 			% Variable names
plevstrs={'850';'200';'toa';'2m';'sfc';'500'};			% Must be same size as varname; for variables with no plevels, use sfc or 10m
groups={'GMAO';'RSMAS';'ESRL';'ECCC';'NRL';'EMC'};     		% Modeling Groups (must be same # elements as models below)
models={'GEOS_V2p1';'CCSM4';'FIMr1p1';'GEM';'NESM';'GEFS'};	% Model Name (must be same # of elements as groups above)
dfv=-9.99e-8;							% Default missing_value or FillValue if not specified in input data file
type='hindcast';						% hindcast or forecast
clobber=1; 							% clobber=1 -- overwrite the data file in output directory, clobber~=1, do not overwrite
%--------------------------------------------------------------------------------------
% DO NOT MODIFY
%--------------------------------------------------------------------------------------
url='http://iridl.ldeo.columbia.edu/SOURCES/.Models/.SubX/'; % IRI URL
nvars=numel(varnames);
nmodels=numel(models);

%---------------------------------------------------------------------------------------
% Main Program  
%---------------------------------------------------------------------------------------

for ivar=1:nvars

   % Define variable name and level
   varname=char(varnames(ivar));
   plevstr=char(plevstrs(ivar));
   
   for imodel=1:nmodels

      % Define the model and group
      model=char(models(imodel));
      group=char(groups(imodel));
 
      % Open File
      inFname=strcat(url,'.',group,'/.',model,'/.',type,'/.',varname,'/dods'); % input filename
      ncid=netcdf.open(char(inFname),'NC_NOWRITE');

      % Determine number of variables, dimensions, etc. in file
      [ndims,nvars,ngatts,unlimdimid] = netcdf.inq(ncid);

      % Determine dimensions and size of dimensions
      for i=0:ndims-1
        [dimname, dimlen] = netcdf.inqDim(ncid,i);
        dimlens(i+1)=dimlen;
        [j,nchars]=size(dimname);
        dimnames(i+1,1:nchars)=dimname(:);

        varid=netcdf.inqVarID(ncid,dimname);
        switch(dimname)
         case 'X'
          lon=netcdf.getVar(ncid,varid);
         case 'Y'
          lat=netcdf.getVar(ncid,varid);
         case 'L'
          leads=netcdf.getVar(ncid,varid);
         case 'M'
          ens=netcdf.getVar(ncid,varid);
          nens=numel(ens);
         case 'S'
          ics=netcdf.getVar(ncid,varid);
          unitsic=netcdf.getAtt(ncid,varid,'units');
          nics=numel(ics);
         case 'P'
          levs=netcdf.getVar(ncid,varid);
          plev=find(levs==str2num(plevstr));
         otherwise 
           % do nothing - should probably exit with error message since no expectation for this
        end % switch on dimname
      end % dims

      % Convert netCDF days since values to calendar dates
      startdates=nctime2datestrdaily(ics,unitsic);
   
      % Get ID of specified variable
      varid=netcdf.inqVarID(ncid,char(varname));
   
      % Get information about specified variable
      [v1, xtype, dimid, natt] = netcdf.inqVar(ncid,varid);
      vardimlen=dimlens(dimid+1);

      % Set the dimensions to read - [nlons,nlats,nleads,nens,nlevs,nics]
      if (ndims == 6)  % multilevel data
         %count=[vardimlen(1),vardimlen(2),vardimlen(3),1,1,1];
         count=[vardimlen(1),vardimlen(2),1,vardimlen(4),1,1];
      else % single level data
         %count=[vardimlen(1),vardimlen(2),vardimlen(3),1,1];
         count=[vardimlen(1),vardimlen(2),1,vardimlen(4),1];
      end 

      % Create Output directory if needed
      outDir=strcat(outPath,type,'/',varname,plevstr,'/daily/full/',group,'-',model,'/');
      if (exist((char(outDir)),'dir') ~= 7)
           mkdir(char(outDir));
      end

      % Set Global Attribute Values
      units=netcdf.getAtt(ncid,varid,'units');
      longtitle=netcdf.getAtt(ncid,varid,'long_name');
      title=longtitle;
      fillValue=getFillValue(inFname,varname,dfv);
      units=netcdf.getAtt(ncid,varid,'units');
      comments='SubX project http://cola.gmu.edu/~kpegion/subx/';
      source='SubX IRI';
      institution='IRI';

      % Loop over all ensemble members
      for iens=0:nens-1

         % Set the ensemble member string for output file
         ee=int2str(iens+1);
  
         % Loop over and read all start dates
         %for i=0:nics-1
         for i=0:0
          
            % Set the starting point to read data 
            if (ndims == 6) % multilevel data
               %start=[0,0,0,iens,plev-1,i];
               start=[0,0,i,0,iens,plev-1];
            else % single level data
               %start=[0,0,0,iens,i];
               start=[0,0,i,0,iens];
            end

            % Read all leads, lats, lons for a single start date, ensemble member, and pressure level
            % Resulting array is of size data[nx,ny,nlead] 
            data=squeeze(netcdf.getVar(ncid,varid,start,count));

            % Construct output filename
            ofname=strcat(outDir,varname,'_',char(plevstr),'_',group,'-',model,'_',char(startdates(i+1,:)),'.e',ee,'.daily.nc');

            % Check to see if ofname already exists; if clobber=1, delete file and overwrite; otherwise do not overwrite file
            if (exist(ofname,'file') == 2)
              if (clobber==1)
                 % Remove output file
                 delete(ofname);  

                 % Write data by start date
                 ofname
                 setupNetCDF3D(ofname,lon,lat,leads,unitsic,fillValue);
                 writeNetCDFGlobalAtts(ofname,title,longtitle,comments,institution,source,mfilename());
                 writeNetCDFData3D(ofname,data,units,varname,varname,fillValue);

              end % if clobber==1
            else
              % Write data by start date
              ofname
              setupNetCDF3D(ofname,lon,lat,leads,unitsic,fillValue);
              writeNetCDFGlobalAtts(ofname,title,longtitle,comments,institution,source,mfilename());
              writeNetCDFData3D(ofname,data,units,varname,varname,fillValue);

            end % ifname exists
             
         end %nics

      end %nens

      % Close input netcdf File
      netcdf.close(ncid);

   end % nmodels

end % nvars

