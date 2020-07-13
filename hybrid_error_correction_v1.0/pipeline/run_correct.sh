#!/bin/bash

echo ==========start at : `date` ========== && \

source /ifs4/BC_RD/USER/lizhixin/my_project/hybrid_error_correction_v1.0/pipeline/env.sh
python ./split_fastq/generate_qsub_sh.py ./split_bam && \

echo ==========end at : `date` ==========
