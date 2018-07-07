README
------

This code assumes you have python installed via `anaconda <https://anaconda.org/anaconda/python>`__. See notes `here <https://sites.google.com/view/raybellwaves/pythonrsmas>`__ for installing python.

To setup and run:

.. parsed-literal:: 
    
    $ git clone https://github.com/kpegion/SubX.git
    $ cd Python
    $ conda env create -f ci/requirements-py36.yml
    $ conda activate SubX

The scripts are designed to be run in order:

1. download_data
2. create_climatology
3. create_anomalies
4. create_obs_anomalies
