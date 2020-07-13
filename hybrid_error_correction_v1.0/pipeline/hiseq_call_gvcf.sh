#!/bin/bash
# Program: hiseq_call_gvcf module
# Version: 0.1
# Contact: Zhixin Li <lizhixin@genomics.cn>

prefix=$1
# prefix=arabidopsis
fq1=$2
# fq1=/opt/lustresz/BC_PMO_P0/BC_RD/dengtq/01.Pacbio/00.data/arabidopsis/Illumina_2x300_R1.fastq.gz
fq2=$3
# fq2=/opt/lustresz/BC_PMO_P0/BC_RD/dengtq/01.Pacbio/00.data/arabidopsis/Illumina_2x300_R2.fastq.gz
# ref.fasta must create bwa index, samtools faidx and picard dict!!!
ref=$4
# ref=/ifs4/BC_RD/USER/lizhixin/database/arabidopsis_TAIR9/TAIR9_chr_all.fasta
# if ref.fasta < 50M, set t=16; if ref.fasta > 100M, set t=32
t=$5
# t=32
java_mem=$6
# java_mem=30g
hiseq_RG="@RG\tID:${prefix}\tPL:illumina\tPU:110115_I270_FC81CBVABXX_L5_HUMiqvDBTDBCAPE\tLB:${prefix}\tSM:${prefix}\tCN:BGI"
java_path="/ifs4/BC_PUB/biosoft/pipeline/DNA/DNA_HiSeqWGS/DNA_HiSeqWGS_2015a/bin/java/jre1.7.0_55/bin/java"
# some place only support GATK3.3, don't use 3.6!!!
GATK="/ifs4/BC_PUB/biosoft/pipeline/DNA/DNA_HiSeqWGS/DNA_HiSeqWGS_2015a/bin/GenomeAnalysisTK-3.3-0/GenomeAnalysisTK.jar"
picard="/ifs4/BC_PUB/biosoft/pipeline/DNA/DNA_HiSeqWGS/DNA_HiSeqWGS_2015a/bin/picard"

echo ==========start at : `date` ========== && \
source /ifs4/BC_RD/USER/lizhixin/my_project/hybrid_error_correction_v1.0/pipeline/env.sh
#--------------------------bwa------------------------------
# GATK only support reads group bam
bwa mem -t $t -M -Y -R $hiseq_RG $ref $fq1 $fq2 | samtools sort - ${prefix}.sort && \
samtools index ${prefix}.sort.bam && \
samtools view -F 4 -b ${prefix}.sort.bam > ${prefix}.sort.filter_for_stat.bam && \

#--------------------MarkDuplicates.jar---------------------
$java_path -Xmx$java_mem -jar $picard/MarkDuplicates.jar I=./${prefix}.sort.bam O=./${prefix}.markdup.bam METRICS_FILE=./${prefix}.markdup.bam.mat && \
$java_path -Xmx$java_mem -jar $picard/BuildBamIndex.jar I=./${prefix}.markdup.bam O=./${prefix}.markdup.bam.bai && \

#------------------RealignerTargetCreator-------------------
$java_path -Xmx$java_mem -jar $GATK -T RealignerTargetCreator -R $ref -I ${prefix}.markdup.bam -o ./${prefix}.intervals && \
$java_path -Xmx$java_mem -jar $GATK -T IndelRealigner -R $ref -I ${prefix}.markdup.bam -targetIntervals ./${prefix}.intervals -o ./${prefix}.realign.bam && \

#--------------HaplotypeCaller----no_-nct_5-----------------
##### ERROR MESSAGE: Invalid command line: Argument nt has a bad value: The analysis HaplotypeCaller currently does not support parallel execution with nt.  Please run your analysis without the nt option.
$java_path -Xmx$java_mem -jar $GATK -T HaplotypeCaller -nct $t -R $ref -I ./${prefix}.realign.bam --emitRefConfidence BP_RESOLUTION --heterozygosity 0.01 --indel_heterozygosity 0.01 --variant_index_type LINEAR --variant_index_parameter 128000 -o ./hiseq.g.vcf && \
#----------manual run rest gvcf----------------------------
# $java_path -Xmx$java_mem -jar $GATK -T HaplotypeCaller -nct $t -R $ref -I ./${prefix}.realign.bam --emitRefConfidence BP_RESOLUTION --heterozygosity 0.01 --indel_heterozygosity 0.01 --variant_index_type LINEAR -L rest.bed --variant_index_parameter 128000 -o ./hiseq.g.vcf && \

bgzip hiseq.g.vcf && \
tabix -p vcf hiseq.g.vcf.gz && \
bcftools index hiseq.g.vcf.gz && \

# abspath=$(cd `dirname $0`; pwd) && \
# ln -s ${abspath}/hiseq.g.vcf* ../correction/ && \
echo ==========end at : `date` ==========
