#!/bin/sh
#BSUB -J create_ts_climatology.py
#BSUB -o logs/create_ts_climatology.out
#BSUB -e logs/create_ts_climatology.err
#BSUB -W 1:00
#BSUB -q general
#BSUB -n 1
#
python create_ts_climatology.py
