#!/bin/sh
#BSUB -J create_ts_daily_lead.py
#BSUB -o logs/create_ts_daily_lead.out
#BSUB -e logs/create_ts_daily_lead.err
#BSUB -W 1:00
#BSUB -q general
#BSUB -n 1
#
python create_ts_daily_lead.py
