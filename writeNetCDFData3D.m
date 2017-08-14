%================================================================================================
%  This function write a 3D (lon,lat,tim) dataset to a netcdf file
%================================================================================================
function []=writeNetCDFData3D(fname,data,units,name,longname,fillValue)

% Open File
ncid = netcdf.open(char(fname),'WRITE');

% Dimension IDs

dimlat=netcdf.inqDimID(ncid,'lat');
dimlon=netcdf.inqDimID(ncid,'lon');
dimtime=netcdf.inqDimID(ncid,'time');

%Add Variable
varid = netcdf.defVar(ncid,char(name),'double',[dimlon,dimlat,dimtime]);
netcdf.putAtt(ncid,varid,'name',char(name)');
netcdf.putAtt(ncid,varid,'long_name',char(longname));
netcdf.putAtt(ncid,varid,'units',char(units));
netcdf.defVarFill(ncid,varid,false,fillValue);
netcdf.putVar(ncid,varid,data);


% Close File
netcdf.close(ncid);
