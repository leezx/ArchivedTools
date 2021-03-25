#!/bin/bash
#PBS -l nodes=1:ppn=12
#PBS -l mem=120G
#PBS -l walltime=48:00:00
#PBS -q large
#PBS -N UE-D60-BO
cd $PBS_O_WORKDIR
sh UE-D60-BO.sh && echo job-done
