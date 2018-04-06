clear

%--------------------------------------------------------------------------------------
% Variables to be modified by user
%--------------------------------------------------------------------------------------

outPath='/scratch/kpegion/testSubX/swapdim/matlab/';
varnames={'ua';'ua';'rlut';'tas';'ts';'zg';'va';'va';'pr';'zg'};                        % Variable names
plevstrs={'850';'200';'toa';'2m';'sfc';'500';'200';'850';'sfc';'200'};                  % Must be same size as varname; for variables with no plevels, use sfc or 10m
groups={'GMAO';'RSMAS';'ESRL';'ECCC';'NRL';'EMC'};              % Modeling Groups (must be same # elements as models below)
models={'GEOS_V2p1';'CCSM4';'FIMr1p1';'GEM';'NESM';'GEFS'};     % Model Name (must be same # of elements as groups above)

dfv=-9.99e-8;                                                   % Default missing_value or FillValue if not specified in input data file
type='hindcast';                                                % hindcast or forecast

%--------------------------------------------------------------------------------------
% DO NOT MODIFY
%--------------------------------------------------------------------------------------
url='http://iridl.ldeo.columbia.edu/home/.mbell/.SubX/'; % IRI URL
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

       fprintf('%s%s%s%s%s%s\n','Getting: ',group,'-',model,' ',varname)

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
          nens=1;
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
      startdates=nctime2datestrdaily(double(ics),unitsic);

      % Get ID of specified variable
      varid=netcdf.inqVarID(ncid,char(varname));

      % Get information about specified variable
      [v1, xtype, dimid, natt] = netcdf.inqVar(ncid,varid);
      vardimlen=dimlens(dimid+1);

      % Set the dimensions to read - [nlons,nlats,nleads,nens,nlevs,nics]
      if (ndims == 6)  % multilevel data
         count=[vardimlen(1),vardimlen(2),vardimlen(3),1,1,1];
      else % single level data
         count=[vardimlen(1),vardimlen(2),vardimlen(3),1,1];
      end

      % Create Output directory if needed
      outDir=strcat(outPath,type,'/',varname,plevstr,'/daily/full/',group,'-',model,'/');
      if (exist((char(outDir)),'dir') ~= 7)
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

         for i=0:nics-1

         % Loop over and read all start dates
          imn=str2num(startdates(i+1,5:6));
          iyr=str2num(startdates(i+1,1:4));
          idy=str2num(startdates(i+1,7:8));

            % Construct output filename
            ofname=strcat(outDir,varname,'_',char(plevstr),'_',group,'-',model,'_',char(startdates(i+1,:)),'.e',ee,'.daily.nc');

            % Set the starting point to read data 
            if (ndims == 6) % multilevel data
               start=[0,0,0,iens,i,plev-1];
            else % single level data
               start=[0,0,0,iens,i];
            end

                 % Read all leads, lats, lons for a single start date, ensemble member, and pressure level
                 % Resulting array is of size data[nx,ny,nlead] 
                 data=squeeze(netcdf.getVar(ncid,varid,start,count));

                 fprintf('%s%s\n','Writing File: ',ofname)

                 % Write data by start date
                 setupNetCDF3D(ofname,lon,lat,leads,unitsic,fillValue,'NC_FLOAT');
                 writeNetCDFGlobalAtts(ofname,title,longtitle,comments,institution,source,mfilename());
                 writeNetCDFData3D(ofname,data,units,varname,varname,fillValue,'NC_FLOAT');

         end %nics

      end %nens

      % Close input netcdf File
      netcdf.close(ncid);

   end % nmodels
