clear all;

% Set Path for SubX Matlab library
userpath('../lib');
%**************************************************************************************


%--------------------------------------------------------------------------------------
% Variables to be modified by user
%--------------------------------------------------------------------------------------
inPath='/shared/subx/hindcast/'
outPath=inPath;                                 % User output directory

varnames={'tas';'pr';'zg';'ua';'ua';'rlut';'ts';'zg';'va';'va'};                        % Variable names
plevstrs={'2m';'sfc';'500';'850';'200';'toa';'sfc';'200';'200';'850'};                  % Must be same size as varname; for variables with no plevels, use sfc,10m,toa,etc
nvars=numel(varnames);

imn1=1;
imn2=12;

nx=360;
ny=181;
lon=0.0:1:359.9;
lat=-90.0:1:90.0;

groups={'RSMAS';'ESRL';'ECCC';'EMC';'GMAO';'NRL';'NCEP'};
models={'CCSM4';'FIMr1p1';'GEM';'GEFS';'GEOS_V2p1';'NESM';'CFSv2'};    % Model Name (must be same # of elements as groups above)
syrs=[1999,1999,1999,1999,1999,1999,1999];
eyrs=[2015,2015,2014,2015,2015,2015,2015];
nleads=[45,32,32,35,45,45,44];
nenss=[3,4,4,11,4,1,4];
nmodels=numel(models);
nmodels=numel(models)-1;

dpml=[31;29;31;30;31;30;31;31;30;31;30;31];
dpmnl=[31;28;31;30;31;30;31;31;30;31;30;31];
nmpyr=12;
verbose=1;

% Set Global Attribute Values for netcdf
longtitle='SubX Anomalies';
title=longtitle;
units='unitless';
unitst='days since 1960-01-01';
comments='SubX project http://cola.gmu.edu/~kpegion/subx/';
source='SubX IRI';
institution='IRI';

%---------------------------------------------------------------------------------------
% Main Program  
%---------------------------------------------------------------------------------------

   % Loop over models
   for imodel=1:nmodels

      % Define the model and group
      model=char(models(imodel));
      group=char(groups(imodel));
      syr=syrs(imodel);
      eyr=eyrs(imodel);
      nyr=eyr-syr+1;
      nlead=nleads(imodel);
      nens=nenss(imodel);
      time=0.5:1:nlead;

      for ivar=3:nvars

         varname=char(varnames(ivar));
         levstr=char(plevstrs(ivar));

         % Define input directory
         inDir1=strcat(inPath,varname,levstr,'/daily/full/',group,'-',model,'/');
         inDir2=strcat(inPath,varname,levstr,'/daily/climo/',group,'-',model,'/');

         % Loop over all years
         for iyr=syr:eyr

            yyyy=num2str(iyr);

             dpm=dpmnl;
             if (mod(iyr,4)==0)
               dpm=dpml;
             end

             % Loop over months
             for imn=imn1:imn2

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
                mmdd=strcat(mm,dd);

                % Create Output directory if needed
                outDir=strcat(outPath,varname,levstr,'/daily/anoms/',group,'-',model,'/');
                if (exist((char(outDir)),'dir') ~= 7)
                   mkdir(char(outDir));
                end
                ofname=char(strcat(outDir,varname,'_',levstr,'_',group,'-',model,'_',yyyymmdd,'.anoms.daily.nc'));

                % Declare arrays
                data=NaN(nx,ny,nlead);
                anoms=NaN(nx,ny,nlead);
                climo=NaN(nx,ny,nlead);

                % Create Filename
                inFname1=char(strcat(inDir1,varname,'_',levstr,'_',group,'-',model,'_',yyyymmdd,'.emean.daily.nc'));
                inFname2=char(strcat(inDir2,varname,'_',group,'-',model,'_',mmdd,'.climo.p.nc'));

                if (exist(inFname1,'file') == 2)

                   inFname1
                   inFname2
                   %  Read Data
                   [lon,lat,time,unitst,tmpdata,units,fillValue]=readNetCDFData3D(inFname1,varname);
                   data(:,:,:)=tmpdata;
                   [lon,lat,timec,unitstc,tmpclimo,unitsc,fillValuec]=readNetCDFData3D(inFname2,varname);
                   climo(:,:,:)=tmpclimo;

                end % file exists

                %Make anomalies
                anoms(:,:,:)=data(:,:,:)-climo(:,:,:);

                % Write data
                if (verbose==1)
                     fprintf('%s%s\n','Writing File: ',char(ofname))
                end

                setupNetCDF3D(ofname,lon,lat,time,unitst,fillValue,'NC_FLOAT');
                writeNetCDFGlobalAtts(ofname,title,longtitle,comments,institution,source,mfilename());
                writeNetCDFData3D(ofname,single(anoms),units,varname,varname,fillValue,'NC_FLOAT');
                min(min(min(anoms)))
                max(max(max(anoms)))

                clear data;
                clear tmpdata;
                clear anoms;
                clear climo;
                
          end % day
        end % month
      end % year
   end %vars
end % nmodels                
