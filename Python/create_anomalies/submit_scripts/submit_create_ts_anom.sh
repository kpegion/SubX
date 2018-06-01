#!/bin/sh
#BSUB -J create_ts_anomalies.py
#BSUB -o logs/create_ts_anomalies.out
#BSUB -e logs/create_ts_anomalies.err
#BSUB -W 24:00
#BSUB -q general
#BSUB -n 1
#
python create_ts_anomalies.py
