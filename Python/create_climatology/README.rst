README
------

This repository contains python code for creating daily climatologies of SubX data.

This code assumes you have used the code in ``download_data/`` to generate the files.

- The shell script ``generate_ts_clim.ksh`` will generate a python script to create a daily climatology. To setup and run:

.. parsed-literal:: 
 
    $ conda activate SubX
    $ # edit variables in generate_ts_clim.ksh
    $ chomd u+x generate_ts_clim.ksh
    $ ./generate_ts_clim.ksh
    $ # python create_ts_climatology.py

.. image:: img/example.png
