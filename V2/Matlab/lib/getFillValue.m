function [fillValue]=getFillValue(fname,varname,dfv)

      % Look for FillValue or missing_value -- if not present, set fillValue to default (dfv)
      try
         fillValue=ncreadatt(char(fname),varname,'FillValue');
      catch exception
        if strcmp(exception.identifier,'MATLAB:imagesci:netcdf:libraryFailure');

         % Look for missing_value
         try
            fillValue=ncreadatt(char(fname),varname,'missing_value');
         catch exception
            if strcmp(exception.identifier,'MATLAB:imagesci:netcdf:libraryFailure');
              fillValue=dfv;
            end %if catch exception
         end % end try missing_value

       end % if catch exception
      end % try fillValue
