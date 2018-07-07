README
------

This repository contains python code for downloading SubX data.

- The shell script ``generate_full_py_ens_files.ksh`` will generate python scripts to download each ensemble member seperately for the chosen model etc. These can then be run in parallel. 

- ``generate_ts_py_ens_files.ksh`` generates python scripts to download each ensemble member for one location. 

To setup and run:

.. parsed-literal:: 
 
    $ # edit variables in generate_ts_py_ens_files.ksh
    $ chmod u+x generate_ts_py_ens_files.ksh
    $ ./generate_ts_py_ens_files.ksh
    $ # python getSubXdatats_e1.py

*Note: Sometimes when running* ``getSubXdatats_e*.py`` *in parallel all but one will fail as they all try to create the data directory. In this case just run them again by hand.*
