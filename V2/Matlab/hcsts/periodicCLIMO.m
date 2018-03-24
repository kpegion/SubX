clear all;

% Set Path for SubX Matlab library
userpath('../lib/');

%**************************************************************************************
% periodicCLIMO.m
%
%  Description:
%   Calculates the Climatology for SubX Hindcasts from Ensemble Mean fields
%   for all models and Priority 1 Variables.  This program requires that the ensemble mean
%   has already been calculated for each start date.
%  
%  External Functions/Subroutines (from SubX Matlab Library):
%     setupNetCDF3D.m
%     writeNetCDFGlobalAtts.m
%     writeNetCDFData3D.m
%     getFillValue.m
%     nanfastsmooth.m
%
%  Input:
%  From files produced by calcENSMEANFieldHCAST.m
%
%  Output:
%   Files are of the form <varname>_<group>-<model>'_'<mmdd>.climo.p.nc, where 
%   <mmdd> - 2-digit month (mm) and 2-digit day (dd)
%   <group> -- modeling group
%   <model> -- model name
%   <varname> - user specified -- will be same as input varname
%
%   The output directory that the file is placed in is:
%    <outPath>/<varname><plevstr>/daily/climo/<group>-<model>, where
%    <outPath> - user specified
%    <plevstr> - pressure level (e.g. 200, 500, 850 for hPa, sfc for surface, or 10m for 10-meter,toa for top of atm)
%    /daily -- indicates daily data 
%    /climo/ -- indicates climoatology fields
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

% Input and Output Directories
inPath='/shared/subx/hindcast/'; % Input directory
outPath=inPath;                  % User output directory

% Variables
varnames={'tas';'pr';'zg';'ua';'ua';'rlut';'ts';'va';'va';'zg'};     % Variable names
levstrs={'2m';'sfc';'500';'850';'200';'toa';'sfc';'200';'850';'200'}; % Variable levels
nvars=numel(varnames);


% Models
groups={'RSMAS';'ESRL';'ECCC';'EMC';'GMAO';'NRL'};           % Modeling Groups
models={'CCSM4';'FIMr1p1';'GEM';'GEFS';'GEOS_V2p1';'NESM'};  % Model Names
syrs=[1999,1999,1999,1999,1999,1999];                        % Model start years
eyrs=[2015,2014,2015,2015,2015,2015];                        % Model end years
nleads=[45,32,32,35,45,45];                                  % Lead Times
nmodels=numel(models);

% Date information
dpml=[31;29;31;30;31;30;31;31;30;31;30;31];  % Not leap
dpmnl=[31;28;31;30;31;30;31;31;30;31;30;31]; % Leap
nmpyr=12; % Number of month per year

% Size of lons/lats
nx=360;
ny=181;

% Smoothing options
smoothwin=31; % Size of window for smoothing climo -- CPC uses 31-days
nantol=1;     % Tolerance for number of NaN values in window -- CPC uses 1
smoothtype=2; % Triangular

% Set Global Attribute Values for netcdf
longtitle='SubX Climatology';
title=longtitle;
units='unitless';
comments='SubX project http://cola.gmu.edu/~kpegion/subx/';
source='SubX IRI';
institution='IRI';

%---------------------------------------------------------------------------------------
% Main Program  
%---------------------------------------------------------------------------------------

% Loop over variables
for ivar=1:nvars

   % Define variable name and level
   varname=char(varnames(ivar));
   levstr=char(levstrs(ivar));                                                                                                         1,1           Top

   % Loop over models
   for imodel=1:nmodels

      % Define the model and group
      model=char(models(imodel));
      group=char(groups(imodel));
      syr=syrs(imodel);
      eyr=eyrs(imodel);
      nyr=eyr-syr+1;
      nlead=nleads(imodel);

      % Create arrays and initialize to NaNs
      data=zeros(nx,ny,nlead,366);
      climo1=NaN(nx,ny,nlead,366);
      climo1ex=NaN(nx,ny,nlead,428);
      climo2=NaN(nx,ny,nlead,428);
      doyct=zeros(nx,ny,nlead,366);

      % Define input directory
      inDir=strcat(inPath,varname,levstr,'/daily/full/',group,'-',model,'/');

      % Loop over all years
      for iyr=syr:eyr

          % Year String
          yyyy=num2str(iyr);

          % Number of days for each month in year -- handles leap year
          dpm=dpmnl;
          if (mod(iyr,4)==0)
            dpm=dpml;
          end

          % Loop over months
          for imn=1:nmpyr

             mm=num2str(imn);
             if (imn<10)
              mm=strcat('0',mm);
             end

           % Loop over days
           for idy=1:dpm(imn)

             dd=num2str(idy);
             if (idy<10)
              dd=strcat('0',dd);
             end
             %Create date string
             yyyymmdd=strcat(yyyy,mm,dd);

             % Determine DOY for each date
             v=datevec(yyyymmdd,'yyyymmdd');
             v0=v;
             v0(:,2:3)=1;
             doy=datenum(v)-datenum(v0)+1;

             % Set DOY for 366-day calendar
             imn=str2num(mm);
             yr=str2num(yyyy);
             if (~mod(yr,4)==0)
                if (imn >=3)
                   doy=doy+1;
                end
             end

             % Create Filename
             inFname=strcat(inDir,varname,'_',levstr,'_',group,'-',model,'_',yyyymmdd,'.emean.daily.nc');

             % Read Data if file exists
             if (exist(inFname,'file') == 2)
                fprintf('%s%s\n','Reading File: ',char(inFname))

                %  Read Data
                [lon,lat,time,unitst,tmpdata,unitsd,fillValue]=readNetCDFData3D(inFname,varname);

                % Accumulate data by ilead,doy,iyr, ignoring NaNs ==> this is slow, but need to save memory; need a faster way
                for i=1:nx
                 for j=1:ny
                   for ilead=1:nlead
                       if (~isnan(tmpdata(i,j,ilead)))
                          data(i,j,ilead,doy)=data(i,j,ilead,doy)+tmpdata(i,j,ilead);
                          doyct(i,j,ilead,doy)=doyct(i,j,ilead,doy)+1;
                       end
                    end
                  end
                end

             else % File Does not Exist

                fprintf('%s%s\n','Cannot Find File: ',char(inFname))

             end % file exists

          end % day
        end % month
      end % year
      
%**************************************************************************************
% CALCULATE CLIMATOLOGY
%**************************************************************************************

      % Loop over leads

      for ilead=1:nlead

         % Divide data by number of years to get noisy climo => this is also slow
         for i=1:nx
          for j=1:ny
            for idoy=1:366
               if doyct(i,j,ilead,idoy)==0
                 climo1(i,j,ilead,idoy)=NaN;
               else
                 climo1(i,j,ilead,idoy)=data(i,j,ilead,idoy)./doyct(i,j,ilead,idoy);
               end
             end
          end
         end

         % Append Dec before Jan and Jan after Dec to handle periodicity
         climo1ex(:,:,:,32:397)=climo1(:,:,:,1:366); % Jan-Dec
         climo1ex(:,:,:,1:31)=climo1(:,:,:,336:366); % Dec before Jan
         climo1ex(:,:,:,398:428)=climo1(:,:,:,1:31); % Jan after Dec


         % Apply filter to get smooth climo -- 2=triangular; 1=at least one value in window must be not NaN
         for i=1:nx
           for j=1:ny
              climo2(i,j,ilead,:)=nanfastsmooth(squeeze(climo1ex(i,j,ilead,:)),smoothwin,smoothtype,nantol);
           end
         end

      end %ilead
      
matlab.updateSubXHCSTSIRIGEM.m.out   updateSubXHCSTSIRIGEM.m
matlab.updateSubXHCSTSIRINESM.m.out  updateSubXHCSTSIRIGEOS.m
nesm.out                             updateSubXHCSTSIRIGEOSZ500.m
testGOESfillvalue.m                  updateSubXHCSTSIRI.m
testnrl.m                            updateSubXHCSTSIRINESM.m
updateSubXHCSTSIRICFS.m              updateSubXHCSTSIRIRSMASswapdim.m
[kpegion@atlas1 updaterecovery]$ ls -ltr
total 2252
-rw-r--r-- 1 kpegion users     7811 Dec 18 21:09 updateSubXHCSTSIRI.m
-rw-r--r-- 1 kpegion users      525 Jan  6 14:33 getdata.m
-rw-r--r-- 1 kpegion users     8100 Jan 24 16:08 updateSubXHCSTSIRIGEMDEC.m
-rw-r--r-- 1 kpegion users     7913 Feb  1 10:30 updateSubXHCSTSIRIFIM.m
-rw-r--r-- 1 kpegion users     7985 Feb  6 20:40 updateSubXHCSTSIRIGEFS.m
-rw-r--r-- 1 kpegion users      714 Feb  8 12:37 getFillValue.m
-rw-r--r-- 1 kpegion users     2939 Feb  8 13:05 testGOESfillvalue.m
-rw-r--r-- 1 kpegion users     7834 Feb  8 16:43 updateSubXHCSTSIRICFS.m
-rw-r--r-- 1 kpegion users      302 Feb 13 19:46 testnrl.m
-rw-r--r-- 1 kpegion users     8111 Feb 14 12:38 updateSubXHCSTSIRIGEOSZ500.m
-rw-r--r-- 1 kpegion users     8179 Feb 19 22:38 updateSubXHCSTSIRIGEOS.m
-rw-r--r-- 1 kpegion users     7999 Mar  7 17:32 updateSubXHCSTSIRIRSMASswapdim.m
-rw-r--r-- 1 kpegion users     8002 Mar 13 15:59 updateSubXHCSTSIRIGEM.m
-rw-r--r-- 1 kpegion users        0 Mar 13 16:00 gem.out
-rw-r--r-- 1 kpegion users 15894060 Mar 13 16:59 matlab.updateSubXHCSTSIRIGEM.m.out
-rw-r--r-- 1 kpegion users     8102 Mar 24 11:56 updateSubXHCSTSIRINESM.m
-rw-r--r-- 1 kpegion users   242617 Mar 24 11:58 matlab.updateSubXHCSTSIRINESM.m.out
-rw-r--r-- 1 kpegion users       40 Mar 24 11:58 nesm.out
[kpegion@atlas1 updaterecovery]$ vi updateSubXHCSTSIRIGEM.m
[kpegion@atlas1 updaterecovery]$ runmatlab.sh updateSubXHCSTSIRIGEM.m 2>& gem.out&
[1] 61894
[kpegion@atlas1 updaterecovery]$ clear

[kpegion@atlas1 updaterecovery]$ cd
[kpegion@atlas1 ~]$ ls
anaconda2  classes  grads           idl    matlab                     matlab_crash_dump.11038-8  metrics  modules   students
bin        fftpack  heatbudget.ncl  local  matlab_crash_dump.11038-6  matlab_crash_dump.1269-1   models   projects
[kpegion@atlas1 ~]$ cd ca
ca: No such file or directory.
[kpegion@atlas1 ~]$ ls
anaconda2  classes  grads           idl    matlab                     matlab_crash_dump.11038-8  metrics  modules   students
bin        fftpack  heatbudget.ncl  local  matlab_crash_dump.11038-6  matlab_crash_dump.1269-1   models   projects
[kpegion@atlas1 ~]$ cd classes/
[kpegion@atlas1 ~/classes]$ ls
fa2015  fa2016  sp2015  sp2018
[kpegion@atlas1 ~/classes]$ cd sp201
sp2015/ sp2018/ 
[kpegion@atlas1 ~/classes]$ cd sp201
sp201: No such file or directory.
[kpegion@atlas1 ~/classes]$ ls
fa2015  fa2016  sp2015  sp2018
[kpegion@atlas1 ~/classes]$ cd sp2018
[kpegion@atlas1 sp2018]$ ls
clim713
[kpegion@atlas1 sp2018]$ cd clim713/
[kpegion@atlas1 clim713]$ ls
codehelp  labs  models
[kpegion@atlas1 clim713]$ cd labs/
[kpegion@atlas1 labs]$ ls
hmwk1  practice  rossby  trop  w2
[kpegion@atlas1 labs]$ cd rossby/
[kpegion@atlas1 rossby]$ ls
rossbyqgfreq.m
[kpegion@atlas1 rossby]$ vi rossbyqgfreq.m 
[kpegion@atlas1 rossby]$ cd ..
[kpegion@atlas1 labs]$ ls
hmwk1  practice  rossby  trop  w2
[kpegion@atlas1 labs]$ cd trop/
[kpegion@atlas1 trop]$ ls
tropdisp.png  tropicaldisp.m
[kpegion@atlas1 trop]$ vi tr
tropdisp.png    tropicaldisp.m  
[kpegion@atlas1 trop]$ vi tropicaldisp.m 
[kpegion@atlas1 trop]$ cd ..
[kpegion@atlas1 labs]$ ls
hmwk1  practice  rossby  trop  w2
[kpegion@atlas1 labs]$ cd ..
[kpegion@atlas1 clim713]$ ls
codehelp  labs  models
[kpegion@atlas1 clim713]$ cd ..
[kpegion@atlas1 sp2018]$ ls
clim713
[kpegion@atlas1 sp2018]$ cd clim713/
[kpegion@atlas1 clim713]$ ls
codehelp  labs  models
[kpegion@atlas1 clim713]$ cd models/
[kpegion@atlas1 models]$ ls
lib  mlmodel  som  sw1  sw2
[kpegion@atlas1 models]$ cd sw2/
[kpegion@atlas1 sw2]$ ls
animate.m  lax_wendroff.m  shallow_water_model.m
[kpegion@atlas1 sw2]$ exit
logout
Connection to atlas1 closed.
[kpegion@cola4 ~]$ ls
anaconda2  classes  grads           idl    matlab                     matlab_crash_dump.11038-8  metrics  modules   students
bin        fftpack  heatbudget.ncl  local  matlab_crash_dump.11038-6  matlab_crash_dump.1269-1   models   projects
[kpegion@cola4 ~]$ cd classes/
[kpegion@cola4 ~/classes]$ ls
fa2015  fa2016  sp2015  sp2018
[kpegion@cola4 ~/classes]$ cd sp2018/clim713/
[kpegion@cola4 clim713]$ ls
codehelp  labs  models
[kpegion@cola4 clim713]$ cd models/
[kpegion@cola4 models]$ ls
lib  mlmodel  som  sw1  sw2
[kpegion@cola4 models]$ cd sw2
[kpegion@cola4 sw2]$ ls
animate.m  lax_wendroff.m  shallow_water_model.m
[kpegion@cola4 sw2]$ ls -ltr
total 13
-rw-r--r-- 1 kpegion users 7623 Mar 23 14:29 shallow_water_model.m
-rw-r--r-- 1 kpegion users 3131 Mar 23 14:29 animate.m
-rw-r--r-- 1 kpegion users 1894 Mar 23 14:31 lax_wendroff.m
[kpegion@cola4 sw2]$ vi animate.m 
[kpegion@cola4 sw2]$ vi shallow_water_model.m 
[kpegion@cola4 sw2]$ matlabg&
[1] 32630
[kpegion@cola4 sw2]$ 
[kpegion@cola4 sw2]$ ls
animate.m  lax_wendroff.m  shallow_water_model.m
[kpegion@cola4 sw2]$ cd
[kpegion@cola4 ~]$ cd projects/
[kpegion@cola4 ~/projects]$ cd SubX/Matlab/lib/
[kpegion@cola4 lib]$ ls
calcacc.m    eof.m            nctime2datestrdaily.m  setupNetCDF3D.m  updateSubXFCSTSIRI.m  writeNetCDFGlobalAtts.m
calcrmse.m   getFillValue.m   readNetCDFData3D.m     setupNetCDF4D.m  writeNetCDFData3D.m
diffdates.m  nanfastsmooth.m  readNetCDFData4D.m     testdates.m      writeNetCDFData4D.m
[kpegion@cola4 lib]$ cd ..
[kpegion@cola4 Matlab]$ ls
bias  fcsts  ftp2iri  hcsts  lib  mjo  mvfiles  nao  old  skill  verif
[kpegion@cola4 Matlab]$ cd hcsts/
[kpegion@cola4 hcsts]$ ls
anomsmemb.out         calcAnomsHCSTEmembers.m  events              matlab.calcAnomsHCSTEmembers.m.out  periodicCLIMO.m
calcAnomsHCSTEmean.m  calcENSMEANFieldHCAST.m  getSubXFieldsIRI.m  old                                 test
[kpegion@cola4 hcsts]$ vi calcENSMEANFieldHCAST.m 
[kpegion@cola4 hcsts]$ cd ../lib/
[kpegion@cola4 lib]$ ls
calcacc.m   diffdates.m  getFillValue.m   nctime2datestrdaily.m  readNetCDFData4D.m  setupNetCDF4D.m  updateSubXFCSTSIRI.m  writeNetCDFData4D.m
calcrmse.m  eof.m        nanfastsmooth.m  readNetCDFData3D.m     setupNetCDF3D.m     testdates.m      writeNetCDFData3D.m   writeNetCDFGlobalAtts.m
[kpegion@cola4 lib]$ vi setupNetCDF3D.m   
[kpegion@cola4 lib]$ vi writeNetCDFData3D.m 
[kpegion@cola4 lib]$ vi calcENSMEANFieldHCAST.m
[kpegion@cola4 lib]$ vi writeNetCDFGlobalAtts.m
[kpegion@cola4 lib]$ vi getFillValue.m 
[kpegion@cola4 lib]$ cd ..
[kpegion@cola4 Matlab]$ ls
bias  fcsts  ftp2iri  hcsts  lib  mjo  mvfiles  nao  old  skill  verif
[kpegion@cola4 Matlab]$ cd hcsts/
[kpegion@cola4 hcsts]$ ls
anomsmemb.out         calcAnomsHCSTEmembers.m  events              matlab.calcAnomsHCSTEmembers.m.out  periodicCLIMO.m
calcAnomsHCSTEmean.m  calcENSMEANFieldHCAST.m  getSubXFieldsIRI.m  old                                 test
[kpegion@cola4 hcsts]$ vi periodicCLIMO.m 


%**************************************************************************************
% WRITE DATA
%**************************************************************************************

      % Create Output directory if needed
      outDir=strcat(outPath,'/',varname,levstr,'/daily/climo/',group,'-',model,'/');
      if (exist((char(outDir)),'dir') ~= 7)
         mkdir(char(outDir));
      end

      % Initialize Day of year to 1 -> Jan 1
      idoy=1;

      % Loop over months
      for imn=1:nmpyr

         % Set month string
         mm=int2str(imn);
         if (imn < 10)
           mm=strcat('0',mm);
         end

         for idy=1:dpml(imn)

            % Set day string
            dd=int2str(idy);
            if (idy < 10)
               dd=strcat('0',dd);
            end

            %2-digit month; 2-digit year string
            mmdd=strcat(mm,dd);

            % Write data to netcdf
            ofname=strcat(outDir,varname,'_',group,'-',model,'_',mmdd,'.climo.p.nc')
            setupNetCDF3D(ofname,lon,lat,time,unitst,fillValue,'NC_FLOAT');
            writeNetCDFGlobalAtts(ofname,title,longtitle,comments,institution,source,mfilename());
            writeNetCDFData3D(ofname,climo2(:,:,:,idoy+31),units,varname,varname,fillValue,'NC_FLOAT');

            % Increment Day of Year 
            idoy=idoy+1;

         end %idy 
      end %imn 

      % Clean up for next model/var 
      clear climo1;
      clear climo1ex;
      clear climo2;
      clear data;
      clear tmpdata;
      
   end % models

end % vars      
