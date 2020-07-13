#!/bin/bash
# Author: LI ZHIXIN
# E-mail: lizhixin@genomics.cn
# Date: 2017-7-24

### Preparation (optional)
#../bin/python3 ../bin/barcode_list_to_fasta.py /ifs4/BC_RD/PROJECT/F16RD11042/lizhixin/prj/single_Cell/2_barcode_split/barcode.list

### Main
../bin/python3 ../bin/bc-split-V1.0.py /ifs4/BC_RD/PROJECT/F16RD11042/lizhixin/prj/single_Cell/2_barcode_split/CL200020292_L01_read_1.fq.gz /ifs4/BC_RD/PROJECT/F16RD11042/lizhixin/prj/single_Cell/2_barcode_split/CL200020292_L01_read_2.fq.gz barcode.fasta

### Statistics (just for test)
#../bin/python3 ../bin/result_stat.py old.barcode.result.txt uniq.barcode.txt
### old.barcode.txt come from old file split_stat_read1.log
### final_barcode.txt is our result
### test result
### old: 32265
### new: 32226
### overlap: 32214

