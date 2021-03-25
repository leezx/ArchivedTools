#!/bin/bash
#PBS -l nodes=1:ppn=12
#PBS -l mem=120G
#PBS -l walltime=48:00:00
#PBS -q large
#PBS -N 7Ala-D60-BO
cd $PBS_O_WORKDIR
sh 7Ala-D60-BO.sh && echo job-done
