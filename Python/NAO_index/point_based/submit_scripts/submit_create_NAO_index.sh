#!/bin/sh
#BSUB -J create_NAO_index.py
#BSUB -o logs/create_NAO_index.out
#BSUB -e logs/create_NAO_index.err
#BSUB -W 24:00
#BSUB -q general
#BSUB -n 1
#
python create_NAO_index.py
