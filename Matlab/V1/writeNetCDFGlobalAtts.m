%================================================================================================
%================================================================================================
function []=writeNetCDFGlobalAtts(fname,title,longtitle,comments,institution,source,matlabSource)

NC_GLOBAL = netcdf.getConstant('NC_GLOBAL');

% Open File
ncid=netcdf.open(char(fname),'WRITE');

% Global Attributes
netcdf.putAtt(ncid,NC_GLOBAL,'title',char(title));
netcdf.putAtt(ncid,NC_GLOBAL,'long_title',char(longtitle));
netcdf.putAtt(ncid,NC_GLOBAL,'comments',char(comments));
netcdf.putAtt(ncid,NC_GLOBAL,'institution',char(institution));
netcdf.putAtt(ncid,NC_GLOBAL,'source',source);
netcdf.putAtt(ncid,NC_GLOBAL,'CreationDate',datestr(now,'yyyy/mm/dd HH:MM:SS'));
netcdf.putAtt(ncid,NC_GLOBAL,'CreatedBy',getenv('LOGNAME'));
netcdf.putAtt(ncid,NC_GLOBAL,'MatlabSource',matlabSource);

% Close File
netcdf.close(ncid);
