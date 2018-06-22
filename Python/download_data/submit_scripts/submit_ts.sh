#!/bin/sh
#BSUB -J getSubXdatats_eens.py
#BSUB -o logs/getSubXdatats_eens.out
#BSUB -e logs/getSubXdatats_eens.err
#BSUB -W 24:00
#BSUB -q general
#BSUB -n 1
#
python getSubXdatats_eens.py
