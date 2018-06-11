README
------

This repository contains python code for creating the NAO index using the method of `Scaife14 <https://agupubs.onlinelibrary.wiley.com/doi/full/10.1002/2014GL059637>`__.

This code assumes you have used the code in ``download_data/``, ``create_climatology/``, ``create_anomalies/`` to generate the files.

- The shell script ``createNAO_index_template.py`` will generate a python script to create the daily NAO index. The code is split into two sections with on/off switches via ``forecast`` and ``ERA_Interim``. It is recommended to run one section at a time to reduce memory usage.
