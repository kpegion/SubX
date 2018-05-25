#!/bin/sh
#BSUB -J getSubXdatafull_eens.py
#BSUB -o logs/getSubXdatafull_eens.out
#BSUB -e logs/getSubXdatafull_eens.err
#BSUB -W 96:00
#BSUB -q general
#BSUB -n 1
#
python getSubXdatafull_eens.py