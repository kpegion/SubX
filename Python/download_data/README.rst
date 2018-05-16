README
------

This repository contains python code for downloading SubX data.

This code assumes you have python installed via `anaconda <https://anaconda.org/anaconda/python>`__. See notes `here <https://sites.google.com/view/raybellwaves/pythonrsmas>`__ for installing python.

The shell script ``generate_full_py_ens_files.ksh`` will generate python scripts to download each ensemble member seperately for the chosen model etc. These can then be run in parallel.

To setup and run:

.. parsed-literal:: 
 
    $ git clone https://github.com/kpegion/SubX.git
    $ cd Python/download_data
    $ conda env create -f requirements-py36.yml
    $ conda activate SubXdata
    $ # edit variables in generate_full_py_ens_files.ksh
    $ chmod u+x generate_full_py_ens_files.ksh
    $ ./generate_full_py_ens_files.ksh
    $ # python getSubXdatafull_e1.py