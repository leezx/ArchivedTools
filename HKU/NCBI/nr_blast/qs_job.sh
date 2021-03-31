#!/bin/bash
#PBS -l nodes=1:ppn=10
#PBS -l mem=80G
#PBS -l walltime=16:00:00
#PBS -q large
#PBS -N formatdb
cd $PBS_O_WORKDIR
date
#gzip -d nr.fa.gz && echo job-done
#gzip -dc nr.fa.gz | /usr/bin/formatdb -i stdin -o T -p T -n "nt" && echo job-done
#/usr/bin/formatdb -i nr.fa -o T -p T -n "nt" && echo job-done
/home/lizhixin/softwares/miniconda2/bin/makeblastdb -in nr.fa -input_type fasta -dbtype prot -title nr -out prot_db && echo job-done
date
