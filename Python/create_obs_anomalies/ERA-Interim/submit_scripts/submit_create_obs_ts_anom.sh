#!/bin/sh
#BSUB -J create_obs_ts_anomalies.py
#BSUB -o logs/create_obs_ts_anomalies.out
#BSUB -e logs/create_obs_ts_anomalies.err
#BSUB -W 1:00
#BSUB -q general
#BSUB -n 1
#
python create_obs_ts_anomalies.py
