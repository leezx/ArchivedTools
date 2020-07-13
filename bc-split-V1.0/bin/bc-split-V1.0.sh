#!/bin/bash
#bc-split-V1.0.sh <read1.fq.gz> <read2.fq.gz> <barcode.fasta>

usage(){
echo "
bc-split-V1.0
Written by Li Zhixin, from 2017.7.24 - present
Last modified 2017.7.28
Description: Fast and accurate barcode&UMI spliter.
--------------------------------------------------------------
sh bc-split-V1.0.sh <read1.fq.gz> <read2.fq.gz> <barcode.fasta>
"
}

if [ -z "$1" ] || [[ $1 == -h ]] || [[ $1 == --help ]]; then
        usage
        exit
fi

read1=$1
read2=$2
barcode_ref=$3

export PATH="$(dirname $0)":$PATH

echo "Work starting..." &&\
FQ_CutIndex -InFq $read2 
mkdir ref &&\
bowtie-build -f $barcode_ref ./ref/barcode &&\
bowtie ./ref/barcode -f barcode1.fasta -S --sam-nohead  --seedmms 1 > barcode1.sam &&\
bowtie ./ref/barcode -f barcode2.fasta -S --sam-nohead  --seedmms 1 > barcode2.sam &&\
rm -r ref &&\
rm barcode1.fasta barcode2.fasta &&\

cat barcode1.sam | cut -f1,2,3 > barcode1.name &&\
cat barcode2.sam | cut -f1,2,3 > barcode2.name &&\
rm barcode1.sam barcode2.sam &&\

paste barcode1.name barcode2.name > total_barcode.txt &&\
rm barcode1.name barcode2.name &&\

cat total_barcode.txt | awk '{if ($2==0 && $5==0){print $1,$3"_"$6}}' > reads_barcode.txt &&\

MyFQ_Merge -InFq $read1 
rm total_barcode.txt &&\

echo "Work done!!!"
