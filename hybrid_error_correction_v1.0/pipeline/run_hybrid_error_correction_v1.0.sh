#!/bin/bash
# Program: Hybrid_error_correction (via bayesian model)
# Version: 0.1
# Contact: Zhixin Li <lizhixin@genomics.cn>

#---------------------step_1: set PATH---------------------------
prefix=DBG_denovo
# hiseq reads and PB reads
fq1=/ifs4/BC_RD/USER/lizhixin/data/chr22/hiseq_reads/R1_chr22.fastq.gz
fq2=/ifs4/BC_RD/USER/lizhixin/data/chr22/hiseq_reads/R2_chr22.fastq.gz
PB_reads=/ifs4/BC_RD/USER/lizhixin/my_project/chr22_asm_ref_nX/20X_platanus_chr22/call_variation/PB_chr22_20X_random.fastq.gz
# ref.fasta must create bwa index, samtools faidx and picard dict!!!
ref=/ifs4/BC_RD/USER/lizhixin/my_project/consensus_extend/denovo_ref/merged_DBG2OLC_denovo.fasta
t=32
java_mem=30g
grid_P="HUMDnab"
grid_q="bc.q"

#---------------------step_2: set DIR and FILE--------------------
mkdir hiseq_gvcf && \
mkdir PB_gvcf && \
mkdir correction && \
cp /ifs4/BC_RD/USER/lizhixin/my_project/hybrid_error_correction_v1.0/pipeline/hiseq_call_gvcf.sh hiseq_gvcf && \
cp /ifs4/BC_RD/USER/lizhixin/my_project/hybrid_error_correction_v1.0/pipeline/PB_call_gvcf.sh PB_gvcf && \
cp /ifs4/BC_RD/USER/lizhixin/my_project/hybrid_error_correction_v1.0/pipeline/cigar.py /ifs4/BC_RD/USER/lizhixin/my_project/hybrid_error_correction_v1.0/pipeline/left_align.py PB_gvcf && \
cp /ifs4/BC_RD/USER/lizhixin/my_project/hybrid_error_correction_v1.0/pipeline/post_stat.sh correction && \
head="#!/bin/bash"
env="source /ifs4/BC_RD/USER/lizhixin/my_project/hybrid_error_correction_v1.0/pipeline/env.sh"
hiseq_cmd="sh hiseq_call_gvcf.sh $prefix $fq1 $fq2 $ref $t $java_mem"
PB_cmd="sh PB_call_gvcf.sh $prefix $PB_reads $ref $t $java_mem"
correct_cmd="python ./generate_qsub_sh.py ../split_bam $grid_P $grid_q"
echo '#!/bin/bash' > ./hiseq_gvcf/run_hiseq_call_gvcf.sh && \
echo "$env" >> ./hiseq_gvcf/run_hiseq_call_gvcf.sh && \
echo "$hiseq_cmd" >> ./hiseq_gvcf/run_hiseq_call_gvcf.sh && \
echo '#!/bin/bash' > ./PB_gvcf/run_PB_call_gvcf.sh && \
echo "$env" >> ./PB_gvcf/run_PB_call_gvcf.sh && \
echo "$PB_cmd" >> ./PB_gvcf/run_PB_call_gvcf.sh && \
echo '#!/bin/bash' > ./correction/run_correct.sh && \
echo "$env" >> ./correction/run_correct.sh && \
echo "$correct_cmd" >> ./correction/run_correct.sh && \

#---------------------step_3: call hiseq and PB GVCF----------------
echo "-----------------------------------------------------------------------------------------"
echo "Step1: Please Manually qsub './hiseq_gvcf/run_hiseq_call_gvcf.sh' and './PB_gvcf/run_PB_call_gvcf.sh'" && \
echo "---------" && \
#---------------------step_4: correct-------------------------------
echo "Step2: If gvcf calling finished, 'sh ./correction/run_correct.sh.', it will auto qsub split command" && \
echo "---------" && \
echo "Note: For big data(genome>=100M, PB or Hiseq>=50X), you need to split jobs(bwa mem and GATK final step)." && \
echo "Note: PB reads must be fastq(.gz) format, if yours is fasta, please trans it, contact Li."
echo "-----------------------------------------------------------------------------------------"
