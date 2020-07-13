#!/bin/bash
# Program: PB_call_gvcf module
# Version: 0.1
# Contact: Zhixin Li <lizhixin@genomics.cn>

prefix=$1
#prefix=hg19_chr22_10X
fasta=$2
#fasta=/ifs4/BC_RD/USER/lizhixin/my_project/10X_pb_chr22/PB_chr22_10X_random.fastq
ref=$3
#ref=/ifs4/BC_RD/USER/lizhixin/database/hg19_nohap_ref/split_chr/chr22.fasta
t=$4
#t=32
java_mem=$5
#java_mem=30g
java_path="/ifs4/BC_PUB/biosoft/pipeline/DNA/DNA_HiSeqWGS/DNA_HiSeqWGS_2015a/bin/java/jre1.7.0_55/bin/java"
GATK="/ifs4/BC_PUB/biosoft/pipeline/DNA/DNA_HiSeqWGS/DNA_HiSeqWGS_2015a/bin/GenomeAnalysisTK-3.3-0/GenomeAnalysisTK.jar"
picard="/ifs4/BC_PUB/biosoft/pipeline/DNA/DNA_HiSeqWGS/DNA_HiSeqWGS_2015a/bin/picard"
java_path1_8="/ifs4/BC_RD/USER/zhanglihua/HiSeqExome/HiSeqExome_v1.1/bin/java/jre1.8.0_101/bin/java"
GATK3_6="/ifs4/BC_RD/USER/zhanglihua/HiSeqExome/HiSeqExome_v1.1/bin/GenomeAnalysisTK-3.6/GenomeAnalysisTK.jar"

echo ==========start at : `date` ========== && \
source /ifs4/BC_RD/USER/lizhixin/my_project/hybrid_error_correction_v1.0/pipeline/env.sh
#---------------------------bwa------------------------------
bwa mem -t $t -x pacbio -B2 -w200 -D200 $ref $fasta | samtools sort - ${prefix} && \
samtools view -F 4 -b ${prefix}.bam | samtools sort -n - ${prefix}_filter_sortByName

#---------------------add read group------------------------
$java_path -Xmx$java_mem -jar $picard/AddOrReplaceReadGroups.jar VALIDATION_STRINGENCY=LENIENT I=${prefix}.bam O=$prefix.rg.bam LB=BGI PL=Pacbio PU=NA SM=$prefix && \
samtools index $prefix.rg.bam && \

#---------------------MarkDuplicates------------------------
$java_path -Xmx$java_mem -jar $picard/MarkDuplicates.jar REMOVE_DUPLICATES=false MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=5000 INPUT=$prefix.rg.bam O=${prefix}.rg.dup.bam METRICS_FILE=${prefix}.rg.dup.bam.mat && \
samtools index ${prefix}.rg.dup.bam && \

#-----------------------left_align---------------------------
python left_align.py -r $ref -m $prefix.rg.dup.bam $prefix.left_align.bam && \
samtools index $prefix.left_align.bam && \

#---------------------IndelRealigner------------------------
$java_path -Xmx$java_mem -jar $GATK -T RealignerTargetCreator --defaultBaseQualities 20 -R $ref -I $prefix.left_align.bam -o $prefix.realign.intervals && \
$java_path -Xmx$java_mem -jar $GATK -T IndelRealigner --defaultBaseQualities 20 -R $ref -I $prefix.left_align.bam -targetIntervals $prefix.realign.intervals -o $prefix.realigned.bam && \

#---------------------UnifiedGenotyper----------------------
$java_path -Xmx$java_mem -jar $GATK -nct $t -T UnifiedGenotyper --genotype_likelihoods_model BOTH --min_base_quality_score 0 --allSitePLs --output_mode EMIT_ALL_SITES -ploidy 2 -R $ref -I $prefix.realigned.bam -o PB.g.vcf && \
#----------manual run rest gvcf----------------------------
# $java_path -Xmx$java_mem -jar $GATK -nct $t -T UnifiedGenotyper --genotype_likelihoods_model BOTH -L rest.bed --min_base_quality_score 0 --allSitePLs --output_mode EMIT_ALL_SITES -ploidy 2 -R $ref -I $prefix.realigned.bam -o PB.g.vcf && \
#--------------------diff version--------------------------
# $java_path1_8 -Xmx$java_mem -jar $GATK3_6 -nct $t -T UnifiedGenotyper --genotype_likelihoods_model BOTH -L rest.bed --min_base_quality_score 0 --allSitePLs --output_mode EMIT_ALL_SITES -ploidy 2 -R $ref -I $prefix.realigned.bam -o PB.g.vcf && \

#------------------------bgzip and index--------------------
bgzip PB.g.vcf && \
tabix -p vcf PB.g.vcf.gz && \
bcftools index PB.g.vcf.gz && \

#---------------------------soft link-----------------------
# abspath=$(cd `dirname $0`; pwd) && \
# ln -s ${abspath}/PB.g.vcf* ../correction/ && \
# ln -s ${abspath}/${prefix}_filter_sortByName.bam ../correction/ && \

#----------------------merger fastq to fasta----------------
python /ifs4/BC_RD/USER/lizhixin/my_project/hybrid_error_correction_v1.0/pipeline/merge_fastq_to_fasta.py $fasta ./ && \
#----for fasta format PB reads
# python /ifs4/BC_RD/USER/lizhixin/script/add_qual_to_merge_fasta.py $fasta ./
bgzip mergefastq.fasta && \
samtools faidx mergefastq.fasta.gz && \

#---------------------------split bam-----------------------
python /ifs4/BC_RD/USER/lizhixin/my_project/hybrid_error_correction_v1.0/pipeline/split_bam_file.py ${prefix}_filter_sortByName.bam ../correction/ && \

mkdir ../correction/split_fastq && \
cp /ifs4/BC_RD/USER/lizhixin/my_project/hybrid_error_correction_v1.0/pipeline/generate_qsub_sh.py ../correction/split_fastq/ && \
cp /ifs4/BC_RD/USER/lizhixin/my_project/hybrid_error_correction_v1.0/pipeline/main_for_denovo_all_I.py ../correction/split_fastq/ && \
mv ../correction/run_correct.sh ../correction/split_fastq/

echo ==========end at : `date` ==========
