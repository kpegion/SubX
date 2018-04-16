clear all;

% Set Path for SubX Matlab library
userpath('../lib/');

%**************************************************************************************
% calcENSMEANFieldHCAST.m 
%
%  Description:
%     Calculates the ensemble mean for each forecast initial time for each model and variable
%     in the SubX hindcast.  This program will make an ensemble mean of whatever ensemble members are
%     present.  Therefore, it is possible to make an ensemble mean of all NaNs or an ensemble mean of 1.
%  
%  External Functions/Subroutines (from SubX Matlab Library):
%     setupNetCDF3D.m
%     writeNetCDFGlobalAtts.m
%     writeNetCDFData3D.m
%     getFillValue.m
%
%  Input: from files produced by getSubXFieldsIRI.m
%
%  Output:
%   Files are of the form <varname>_<levstr>_<group>-<model>_<yyyymmdd>.emean.daily.nc
%   <yyyymmdd> - Initialization Date: 4-digit year (yyyy); 2-digit month (mm); 2-digit day (dd)
%   <group> -- modeling group
%   <model> -- model name
%   <varname> - user specified -- will be same as input varname
%   <levstr> - pressure level (e.g. 200, 500, 850 for hPa, sfc for surface, or 10m for 10-meter,toa for top of atm)
%
%   The output directory that the file is placed in is:
%    <outPath>/<varname><plevstr>/daily/climo/<group>-<model>, where
%    <outPath> - user specified
%    /daily -- indicates daily data 
%    /full/ -- indicates full fields (as opposed to anomalies)
%
%  !!!Important Note!!!!
%     This program takes while to run.  Probably want to run it in the background.
%
%  History:
%
%  2/3/2018 Created Kathy Pegion 
%
%  Project Information:
%   This program was created as part of the Subseasonal Experiment (SubX), a project
%   funded by NOAA/MAPP, ONR, NWS/STI, and NASA/MAP.  Futher information on the SubX 
%   project can be found at http://cola.gmu.edu/kpegion/subx/
%
%**************************************************************************************%
inPath='/shared/subx/hindcast/'; % Input directory
outPath=inPath;                        % User output directory
                                                                                                                                       1,1           Top
varnames={'ua';'ua';'rlut';'zg';'tas';'ts';'va';'va';'zg';'pr'}; % Variable names
plevstrs={'850';'200';'toa';'500';'2m';'sfc';'200';'850';'200';'sfc'}; % Variable levels
nvars=numel(varnames);

% Lats and Lons
lon=0.0:1:359.9;
lat=-90.0:1:90.0;
nx=numel(lon);
ny=numel(lat);

% Model Information
groups={'RSMAS';'ESRL';'ECCC';'EMC';'GMAO';'NRL'};          % Modeling Groups
models={'CCSM4';'FIMr1p1';'GEM';'GEFS';'GEOS_V2p1';'NESM'}; % Model Names
syrs=[1999,1999,1999,1999,1999,1999];                       % Start Year
eyrs=[2015,2015,2014,2015,2015,2015];                       % End Year
nleads=[45,32,32,35,45,45];                                 % Number of leads 
nenss=[3,4,4,11,4,1];                                       % Number of Ensemble members
nmodels=numel(models);                                      % Number of Models

% Date Information
dpml=[31;29;31;30;31;30;31;31;30;31;30;31];  % Days per month (Not leap)
dpmnl=[31;28;31;30;31;30;31;31;30;31;30;31]; % Days per month (leap)
nmpyr=12;                                    % Month per year

% Additional Settings
clobber=1; % =1 means overwrite existing ensemble mean file; =0 mean do not write ensemble mean file if one exists
verbose=1; % Provide information to the screen about program progress

% Set Global Attribute Values for netcdf
longtitle='SubX Ensemble Means';
title=longtitle;
units='unitless';
unitst='days since 1960-01-01';
comments='SubX project http://cola.gmu.edu/~kpegion/subx/';
source='SubX IRI';
institution='IRI';
fillValue=-9.9e8;

%---------------------------------------------------------------------------------------
% Main Program  
%---------------------------------------------------------------------------------------

   % Loop over models
   for imodel=1:nmodels

      % Define the model information
      model=char(models(imodel));
      group=char(groups(imodel));
      syr=syrs(imodel);
      eyr=eyrs(imodel);
      nyr=eyr-syr+1;
      nlead=nleads(imodel);
      nens=nenss(imodel);
      time=0.5:1:nlead;

      % Loop over variables
      for ivar=1:nvars

         % Define variables information  
         varname=char(varnames(ivar));
         levstr=char(plevstrs(ivar));

         % Define input directory
         inDir=strcat(inPath,varname,levstr,'/daily/full/',group,'-',model,'/');

         % Loop over all years
         for iyr=syr:eyr

            % Set year string
            yyyy=num2str(iyr);

             % Get days per month -- handles leap year
             dpm=dpmnl;
             if (mod(iyr,4)==0)
               dpm=dpml;
             end

             % Loop over months
             for imn=1:12

                % Set month string
                mm=num2str(imn);
                if (imn<10)
                    mm=strcat('0',mm);
                end

                % Loop over days
                for idy=1:dpm(imn)
                  % Set the day string
                  dd=num2str(idy);
                  if (idy<10)
                      dd=strcat('0',dd);
                  end

                  %Create date string
                  yyyymmdd=strcat(yyyy,mm,dd);

                  % Create Output directory if needed
                  outDir=strcat(outPath,varname,levstr,'/daily/full/',group,'-',model,'/');
                  if (exist((char(outDir)),'dir') ~= 7)
                     mkdir(char(outDir));
                  end

                  % Create ouput file name
                  ofname=char(strcat(outDir,varname,'_',levstr,'_',group,'-',model,'_',yyyymmdd,'.emean.daily.nc'));

                  % Declare arrays as NaN
                  data=NaN(nx,ny,nlead,nens);
                  emean=NaN(nx,ny,nlead);

                  % Loop over ensemble members
                  for iens=1:nens

                      % Set ensemble string
                      ee=num2str(iens);

                       % Create Filename
                       inFname=strcat(inDir,varname,'_',levstr,'_',group,'-',model,'_',yyyymmdd,'.e',ee,'.daily.nc');

                       % Check if file exists
                       if (exist(inFname,'file') == 2)

                          %  Read Data
                          [lon,lat,time,unitst,tmpdata,units,fillValue]=readNetCDFData3D(inFname,varname);
                          data(:,:,:,iens)=tmpdata;

                       end % file exists

                  end % iens
                  % Check if output file exists

                  if (exist(ofname,'file') == 2)

                      if (clobber==1) % Check if user wants to overwrite existing file

                         % Calculate Ensemble mean
                         emean(:,:,:)=nanmean(data,4);

                         if (verbose==1)
                              fprintf('%s%s\n','Writing File1: ',char(ofname))
                         end

                         % Write data
                         setupNetCDF3D(ofname,lon,lat,time,unitst,fillValue,'NC_FLOAT');
                         writeNetCDFGlobalAtts(ofname,title,longtitle,comments,institution,source,mfilename());
                         writeNetCDFData3D(ofname,emean,units,varname,varname,fillValue,'NC_FLOAT');

                      end % clobber

                  else % File does not exist

                      % Calculate Ensemble mean
                      emean(:,:,:)=nanmean(data,4);

                      if (verbose==1)
                            fprintf('%s%s\n','Writing File2: ',char(ofname))
                      end

                      % Write Data
                      setupNetCDF3D(ofname,lon,lat,time,unitst,fillValue,'NC_FLOAT');
                      writeNetCDFGlobalAtts(ofname,title,longtitle,comments,institution,source,mfilename());
                      writeNetCDFData3D(ofname,emean,units,varname,varname,fillValue,'NC_FLOAT');

                  end % file exists

                  % Clean up
                  clear data;
                  clear emean;
                  clear tmpdata;

            end % day
          end % month
        end % year
     end %vars
  end % nmodels
