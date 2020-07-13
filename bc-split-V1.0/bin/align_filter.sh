#!/bin/bash

#echo " $(dirname $0)"
export PATH="$(dirname $0)":$PATH

mkdir ref 
bowtie-build -f barcode.fasta ./ref/barcode
bowtie ./ref/barcode -f barcode1.fasta -S --sam-nohead --seedmms 1 > barcode1.sam
bowtie ./ref/barcode -f barcode2.fasta -S --sam-nohead --seedmms 1 > barcode2.sam
#bowtie ./ref/barcode -q barcode1.fq -S --sam-nohead --seedmms 1 > barcode1.sam
#bowtie ./ref/barcode -q barcode2.fq -S --sam-nohead --seedmms 1 > barcode2.sam

cat barcode1.sam | cut -f1,2,3 > barcode1.name
cat barcode2.sam | cut -f1,2,3 > barcode2.name

paste barcode1.name barcode2.name > total_barcode.txt
# cat total_barcode.txt | awk '{if($1!=$4){print "ERROR,reads name Unable to corresponding in sam file, please check!!!"; exit 1;}}' &&\
#cat total_barcode.txt | awk '{if($2==0 && $5==0){print $3"_"$6}}' > final_barcode.txt
cat total_barcode.txt | awk '{if ($2==0 && $5==0){print $1,$3"_"$6}}' > reads_barcode.txt
#cat final_barcode.txt | sort | uniq > uniq.barcode.txt
