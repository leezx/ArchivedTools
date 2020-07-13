#!/bin/bash

read2=$1

#/home/heweiming/bin/Tools/iTools Fqtools cutIndex -InFq $read2 -OutFq barcode1.fq.gz -StartCut 1 -LengthCut 10
#/home/heweiming/bin/Tools/iTools Fqtools cutIndex -InFq $read2 -OutFq barcode2.fq.gz -StartCut 29 -LengthCut 10
#/home/heweiming/bin/Tools/iTools Fqtools cutIndex -InFq $read2 -OutFq UMI.fq.gz -StartCut 44 -LengthCut 10
#/home/heweiming/bin/Tools/iTools Formtools Fq2Fa -InFq UMI.fq.gz -OutPut UMI.fasta.gz
#gzip -d UMI.fasta.gz barcode1.fq.gz barcode2.fq.gz

#/ifs4/BC_RD/PROJECT/F16RD11042/lizhixin/prj/single_Cell/2_barcode_split/bc-split-V1.0/C.app/test/Fastq_cut -InFq $read2 -OutFq test.fq

/ifs4/BC_RD/PROJECT/F16RD11042/lizhixin/prj/single_Cell/2_barcode_split/bc-split-V1.0/C.app/iTools_Code/src.bak/Fq/FQ_CutIndex -InFq $read2
