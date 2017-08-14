function [ncdates]=nctime2datestrdaily(times,units)

    hpd=24.0;  % hours per day
    mnph=60.0; % min per hour
    spmn=60.0; % sec per min

    % Parse the time units information
    netcdftime=strsplit(units);
    resolution=char(netcdftime(1));

    yrmodaystr=strsplit(char(netcdftime(3)),'-');
    yyyy=yrmodaystr(1);
    mm=yrmodaystr(2);
    dd=yrmodaystr(3);

    if (numel(netcdftime) > 3) 
       hrmnstr=strsplit(char(netcdftime(4)),':');
       hh=hrmnstr(1);
       mn=hrmnstr(2);
    else
       hh='0';
       mn='0';
    end
    
    % Calculate days since Jan 0,0000 for the reference date given by time units
    startDateInfo=datenum(str2double(yyyy),str2double(mm),str2double(dd),str2double(hh),str2double(mn),0');

    switch(resolution)
       case 'days'
          timetmp=times;
       case 'hours'
          timetmp=times./hpd;
       case 'minutes'
          timetmp=times./(hpd.*mnph);
       case 'seconds'
          timetmp=times./(hpd.*mnph.*spmn);
       otherwise
          error('No idea what to do with these units');
    end 

  ncdates=datestr(double(timetmp)+startDateInfo,'yyyymmdd');

