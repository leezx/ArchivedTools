# parameters
#raw_fq1=/home2/groups/paultam/Zeki/bulk.RNA-Seq.Elly/test/UE02302-N_Diff-D20_1.fastq.gz
#raw_fq2=/home2/groups/paultam/Zeki/bulk.RNA-Seq.Elly/test/UE02302-N_Diff-D20_2.fastq.gz
#fq_dir=/home2/groups/paultam/Zeki/bulk.RNA-Seq.Elly/test/
#sName=UE02302-N_Diff-D20

# ENV
export PATH=/home/lizhixin/softwares/miniconda2/envs/biotools/bin:$PATH

# fix parameters
fq1=${sName}_1.fq.gz
fq2=${sName}_2.fq.gz
out_dir=/home2/groups/paultam/Zeki/bulk.RNA-Seq.Elly/human/results/$sName
cpu=2
#ref=/home/lizhixin/databases/hisat2/grch38/genome
#ref=/home/lizhixin/databases/ensembl.release-90/homo_sapiens/hisat2_index/GRCh38
RSEM_ref=/home/lizhixin/databases/ensembl.release-90/homo_sapiens/RSEM/bowtie2/GRCh38
ref=$RSEM_ref

# filter
#mkdir $out_dir &&\
#/home/lizhixin/softwares/RNA_RNAseq_2017a/software/fqcheck -r $raw_fq1 -c $fq_dir/${sName}_1.fqcheck &&\
#/home/lizhixin/softwares/RNA_RNAseq_2017a/software/fqcheck -r $raw_fq2 -c $fq_dir/${sName}_2.fqcheck &&\
#tile=`` &&\
#/home/lizhixin/softwares/RNA_RNAseq_2017a/Filter/../software/SOAPnuke filter -l 15 -q 0.2 -n 0.05 -i -Q 2 -5 1  -c 2 -1 $raw_fq1 -2 $raw_fq2 -f AGTCGGAGGCCAAGCGGTCTTAGGAAGACAA -r AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGTA $tile -o $out_dir -C $out_dir/$fq1 -D $out_dir/$fq2 -R $out_dir/rawdata.$fq1 -W $out_dir/rawdata.$fq2  &&\

echo "=================step01: fastq filter done!!!=================" &&\

# filter stat
#/home/lizhixin/softwares/RNA_RNAseq_2017a/Filter/../software/fqcheck -r $out_dir/$fq1 -c $out_dir/${sName}_1.fqcheck && \
#/home/lizhixin/softwares/RNA_RNAseq_2017a/Filter/../software/fqcheck -r $out_dir/$fq2 -c $out_dir/${sName}_2.fqcheck && \
#/home/lizhixin/softwares/RNA_RNAseq_2017a/Filter/../software/fqcheck -r $out_dir/rawdata.$fq1 -c $out_dir/rawdata.${sName}_1.fqcheck && \
#/home/lizhixin/softwares/RNA_RNAseq_2017a/Filter/../software/fqcheck -r $out_dir/rawdata.$fq2 -c $out_dir/rawdata.${sName}_2.fqcheck && \
#perl /home/lizhixin/softwares/RNA_RNAseq_2017a/Filter/soapnuke_stat.pl $out_dir/Basic_Statistics_of_Sequencing_Quality.txt $out_dir/Statistics_of_Filtered_Reads.txt >$out_dir/${sName}.filter.stat.xls && \

echo "=================step02: fastq filter stat done!!!================="&&\

# align
#hisat2 --phred64 --sensitive --no-discordant --no-mixed -I 1 -X 1000 -x $ref -1 ${out_dir}/$fq1 -2 ${out_dir}/$fq2 2>${sName}.Map2GenomeStat.xls | samtools view -b -S -o ${sName}.bam
#hisat2 --phred64 --sensitive --no-discordant --no-mixed -I 1 -X 1000 -x $ref -1 ${out_dir}/$fq1 -2 ${out_dir}/$fq2 2>$out_dir/${sName}.Map2GenomeStat.xls | samtools sort - -o $out_dir/${sName}.bam -@ $cpu
#/home/lizhixin/softwares/miniconda2/envs/biotools/bin/hisat2 -q --phred64 --mp 1,1  --np 1 --score-min L,0,-0.1 -X 1000 --no-mixed --no-discordant -p $cpu -k 200 --sensitive -I 1  -x $ref -1 ${out_dir}/$fq1 -2 ${out_dir}/$fq2 2>$out_dir/${sName}.Map2GenomeStat.xls | samtools view -b -S -o $out_dir/${sName}.bam
#/home/lizhixin/softwares/miniconda2/envs/biotools/bin/bowtie2 -q --phred64 --mp 1,1  --np 1 --score-min L,0,-0.1 -X 1000 --no-mixed --no-discordant -p $cpu -k 200 --sensitive -I 1 -x $ref -1 ${out_dir}/$fq1 -2 ${out_dir}/$fq2 2>$out_dir/${sName}.Map2GenomeStat.xls | samtools sort - -o $out_dir/${sName}.bam -@ $cpu
#/home/lizhixin/softwares/miniconda2/envs/biotools/bin/bowtie2 -q --phred64 --sensitive --dpad 0 --gbar 99999999 --mp 1,1 --np 1 --score-min L,0,-0.1 -I 1 -X 1000 --no-mixed --no-discordant  -p 1 -k 200 -x $ref -1 ${out_dir}/$fq1 -2 ${out_dir}/$fq2 2>$out_dir/${sName}.Map2GenomeStat.xls | /home/lizhixin/softwares/miniconda2/envs/biotools/bin/samtools view -b -S -o $out_dir/${sName}.bam - &&\
echo "=================step03: fastq alignment done!!!================="&&\

# RSEM
/software/sequencing/RSEM-1.3.0/rsem-calculate-expression -p $cpu --estimate-rspd --append-names --output-genome-bam --paired-end --bam $out_dir/${sName}.bam $RSEM_ref $out_dir/${sName} &&\

# --star --star-path /home/lizhixin/softwares/miniconda2/envs/biotools/bin
# /home/lizhixin/databases/ensembl.release-90/homo_sapiens/RSEM/STAR/GRCh38
# --bowtie2 --bowtie2-path /home/lizhixin/softwares/miniconda2/envs/biotools/bin		
# /home/lizhixin/databases/ensembl.release-90/homo_sapiens/RSEM/bowtie2/GRCh38		
	
echo "=================step04: transcript quantification done!!!================="

