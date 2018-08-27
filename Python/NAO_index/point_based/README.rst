README
------

This repository contains python code for creating the NAO index. The NAO is defined as a point-based index with the two points calculated as the maximum and minimum winter geopotential height at 500 hPa (Z500) in the leading North Atlantic EOF spatial pattern (20°N-90°N, 80°W-40°E). The two points selected are 65°N, 56°W and 42°N, 38°W. The daily NAO is then calculated as the standardized difference between Z500 anomalies at the two points.

This code assumes you have used the code in ``download_data/``, ``create_climatology/``, ``create_anomalies/`` (and ``create_obs_anomalies/``) to generate the files.

- The shell script ``generate_NAO_index.ksh`` will generate a python script to create the daily NAO index. The code is split into two sections with on/off switches via ``forecast`` and ``ERA_Interim``. It is recommended to run one section at a time to reduce memory usage.

To setup and run:

.. parsed-literal:: 
       
    $ cd Python/NAO_index/point_based
    $ conda activate SubX
    $ # edit variables in generate_NAO_index.ksh
    $ chmod u+x generate_NAO_index.ksh
    $ ./generate_NAO_index.ksh
    $ # python create_NAO_index.py
    $ # switch ERA_Interim on and forecast off
    $ # python create_NAO_index.py

