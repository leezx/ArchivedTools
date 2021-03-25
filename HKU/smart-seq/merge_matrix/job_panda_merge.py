#!/bin/bash
#PBS -l nodes=1:ppn=2
#PBS -l mem=50G
#PBS -l walltime=6:00:00
#PBS -q medium
#PBS -N merge_exp
cd $PBS_O_WORKDIR
date
/home/lizhixin/softwares/miniconda2/bin/python2 panda_merge.py &&\
echo job-done
date
