#!/bin/bash

ref=/ifs4/BC_RD/USER/lizhixin/database/arabidopsis_DBG_15X/arabidopsis_DBG_15X.fasta

cat split_fastq/correct_out/corrected_* > merge_corrected.fastq &&\
cat split_fastq/correct_stat/stat_* > merge_stat.txt &&\
cat split_fastq/correct_stat/bais_file_corrected_* > merge_4_line.txt &&\
cp /ifs4/BC_RD/USER/lizhixin/script/stat_correct_percent_count_I.py ./ &&\
cp /ifs4/BC_RD/USER/lizhixin/script/bwa_mem.sh ./ &&\
cp /ifs4/BC_RD/USER/lizhixin/script/bam_info_stat_for_I.py ./ &&\

python stat_correct_percent_count_I.py merge_corrected.fastq &&\
sh bwa_mem.sh $ref merge_corrected.fastq  &&\
python bam_info_stat_for_I.py corrected_fastq_for_stat.bam
