#!/bin/bash
#PBS -l nodes=1:ppn=1
#PBS -l mem=3G
#PBS -l walltime=6:00:00
#PBS -q small
#PBS -N est 
cd $PBS_O_WORKDIR
date
#script=blastx.sh
#sh $PBS_O_WORKDIR/$script && echo job-done
#/home/lizhixin/softwares/diamond blastx -d /home/lizhixin/databases/ncbi/nr_diamond/nr -q test.merged.transcript.fasta -o test.matches.m8
#/home/lizhixin/softwares/miniconda2/envs/py3/bin/python genebankToFastA.py
sh extract2.sh
date
