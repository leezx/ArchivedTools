#!/bin/bash
#PBS -l nodes=1:ppn=2
#PBS -l mem=10G
#PBS -l walltime=06:00:00
#PBS -q small
#PBS -N example

cd $PBS_O_WORKDIR

# do something  &&\

echo job-done
