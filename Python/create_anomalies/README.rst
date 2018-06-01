README
------

This repository contains python code for creating daily anomalies of SubX data.

This code assumes you have used the code in ``download_data/`` and ``create_climatology/`` to generate the files.

- The shell script ``generate_ts_anom.ksh`` will generate a python script to create daily anomalies.

To setup and run:

.. parsed-literal:: 
 
    $ conda activate SubX
    $ # edit variables in generate_ts_anom.ksh
    $ chomd u+x generate_ts_anom.ksh
    $ ./generate_ts_anom.ksh
    $ # python create_ts_anomalies.py