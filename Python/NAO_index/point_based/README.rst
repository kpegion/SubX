README
------

This repository contains python code for creating the NAO index using the method of `Scaife14 <https://agupubs.onlinelibrary.wiley.com/doi/full/10.1002/2014GL059637>`__.

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

