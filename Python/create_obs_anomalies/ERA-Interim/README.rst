README
------

This repository contains python code for creating ERA-Interim daily anomalies to match SubX data.

This code assumes you have used the code in ``download_data/``, ``create_climatology/`` and ``create_anomalies/`` to generate the files.

- The shell script ``generate_obs_ts_anom.ksh`` will generate a python script to create daily anomalies. The code is split into three sections with on/off switches via ``download_data``, ``create_clim`` and ``create_anom``. It is recommended to run one section at a time to reduce memory usage.
- See `here <https://software.ecmwf.int/wiki/display/CKB/How+to+download+ERA-Interim+data+from+the+ECMWF+data+archive>`__ for information on setting up to downloadng ERA-Interim.

To setup and run:

.. parsed-literal:: 
    
    $ cd Python/create_obs_anomalies
    $ conda env create -f ci/requirements-py35.yml 
    $ conda activate ECMWF
    $ # edit variables in generate_ts_obs_anom.ksh
    $ chmod u+x generate_ts_obs_anom.ksh
    $ # python create_obs_ts_anomalies.py
    $ # switch create_clim on and download_data off
    $ conda deactivate ECMWF
    $ conda activate SubX
    $ # python create_obs_ts_anomalies.py
    $ # switch create_anom on and create_clim off
    $ # python create_obs_ts_anomalies.py
