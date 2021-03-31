#!/bin/bash
#PBS -l nodes=1:ppn=1
#PBS -l mem=3G
#PBS -l walltime=6:00:00
#PBS -q small
#PBS -N gzip
cd $PBS_O_WORKDIR
date
#dir=/home/lizhixin/project/scRNA-seq/rawData/10x/Reeson/Mar_2018/analysis
#script=toFastq.sh
#cd $dir &&
gzip nr.fa && echo job-done
#sh $PBS_O_WORKDIR/$script && echo job-done
# /home/lizhixin/softwares/diamond makedb --in nr.fa -d nr && echo job-done
date
