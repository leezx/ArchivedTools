# go to the fastq folder
cd /home/lizhixin/project/scRNA-seq/rawData/Oct_2018/NganE_scRNA_SS-180801-04a/primary_seq
# if no, create your own softlink

# get absolute path of fastq
ls *_1.fastq.gz | sed "s:^:`pwd`/: " > ../read_1
cd ..
cp read_1 read_2

# get sample name
less read_1 | cut -f10 -d'/' > sample.name
less read_1 | cut -f9-10 -d'/' > sample.name
vi sample.name
# vim
# :%s/foo/bar/g
# %s/_1\.fastq\.gz//g

# no better way
vi read_2
# don't use read_2, disorder!!!
# notepad++ _1. ==> _2.
# vim
# %s/_1\./_2\./g
# %s/_1\.fastq/_2\.fastq/g
paste sample.name read_1 read_2 -d',' > all.sample.csv
# test
# cat all.sample.csv | cut -f2 -d, | xargs ls | grep such
rm read_1 sample.name read_2
############################

wget https://cf.10xgenomics.com/supp/cell-exp/refdata-gex-GRCh38-2020-A.tar.gz
wget https://cf.10xgenomics.com/supp/cell-exp/refdata-gex-mm10-2020-A.tar.gz
# tar zxvf 
# E. coli genome U00096.3 https://www.ncbi.nlm.nih.gov/nuccore/545778205

curl -O https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.9.zip
conda install -c bioconda bowtie2=2.5
pip install cutadapt
conda install -c bioconda fastp=0.23



fastp -i ${fq1}.fq.gz -I ${fq2}.fq.gz -o $out_dir/${sample}_1.fq.gz -O $out_dir/${sample}_2.fq.gz --detect_adapter_for_pe
# check one fastq pair read names

## Build the bowtie2 reference genome index if needed:
bowtie2-build --threads 10 Ecoli_U00096.3.fasta Ecoli
bowtie2-build --threads 24 ../refdata-gex-GRCh38-2020-A/fasta/genome.fa 10x_GRCh38-2020-A/10x_GRCh38-2020-A

ref=/home/da528/ATAC_Analysis/cut_run/zhixin_analysis/reference/bowtie2-ref/10x_GRCh38-2020-A/10x_GRCh38-2020-A
ref_ecoli=/home/da528/ATAC_Analysis/cut_run/zhixin_analysis/reference/bowtie2-ref/Ecoli/Ecoli

# --end-to-end: entire read must align; no clipping (on)
# --no-mixed: suppress unpaired alignments for paired reads
# --no-discordant: suppress discordant alignments for paired reads
# -I: minimum fragment length (0)
# -X: maximum fragment length (500)
# --local: 

# pip install MACS3

bowtie2 -1 /home/da528/ATAC_Analysis/cut_run/zhixin_analysis/HDAC/fastq/D_G1_CKDL220025889-1A_HCY2GDSX5_L1_1.fastq.gz -2 /home/da528/ATAC_Analysis/cut_run/zhixin_analysis/HDAC/fastq/D_G1_CKDL220025889-1A_HCY2GDSX5_L1_2.fastq.gz -x /home/da528/ATAC_Analysis/cut_run/zhixin_analysis/reference/bowtie2-ref/10x_GRCh38-2020-A/10x_GRCh38-2020-A -p 20 -S test.sam 2> test.Map2GenomeStat.xls
 
bowtie2 -U /home/da528/ATAC_Analysis/cut_run/zhixin_analysis/HDAC/fastq/D_G1_CKDL220025889-1A_HCY2GDSX5_L1_1.fastq.gz -x /home/da528/ATAC_Analysis/cut_run/zhixin_analysis/reference/bowtie2-ref/10x_GRCh38-2020-A/10x_GRCh38-2020-A -p 20 -S test.sam 2> test2.Map2GenomeStat.xls

DMSO_HDAC1_1,/home/da528/ATAC_Analysis/cut_run/zhixin_analysis/HDAC/fastq/D_H1_1_CKDL220025889-1A_HCY2GDSX5_L1_1.fastq.gz,/home/da528/ATAC_Analysis/cut_run/zhixin_analysis/HDAC/fastq/D_H1_1_CKDL220025889-1A_HCY2GDSX5_L1_2.fastq.gz

bowtie2 -U /home/da528/ATAC_Analysis/cut_run/zhixin_analysis/HDAC/fastq/D_H1_1_CKDL220025889-1A_HCY2GDSX5_L1_1.fastq.gz -x /home/da528/ATAC_Analysis/cut_run/zhixin_analysis/reference/bowtie2-ref/10x_GRCh38-2020-A/10x_GRCh38-2020-A -p 20 -S test.sam 2> test2.Map2GenomeStat.xls

# check unmapped reads
samtools view -f 4 mybam.bam | cut -f 10 | sort | uniq -c | sort -nr | head




############################
cd ~/project/scRNA-seq/rawData/Oct_2018/
mkdir analysis_TPM
# merge all list
#cat ../NganE_scRNA_SS-1808*/all.sample.csv > all.sample.csv
ln -s ../*/all.sample.csv ./

cp -r tools ~/project/scRNA-seq/rawData/Oct_2018/analysis_TPM/
mkdir merge_matrix  scripts results
cd scripts
ln -s ../tools/generate.scipts_120_ENCC.py ./
ln -s ../tools/scRNA_seq_filter_align_count.matrix.sh ./
ln -s ../all.sample.csv ./
ln -s ../tools/monitor.sh ./
ln -s ../tools/monitor.update.sh ./
ln -s ../tools/nohup_update.sh ./

vi generate.scipts_120_ENCC.py

python3 generate.scipts_120_ENCC.py
ls *-*.sh | wc -l

ls *-*.sh | sed "s:^:`pwd`/: " > file.list
#less monitor.sh
rm database.json
rm *.sign
monitor qsub -f file.list
monitor stat

ls *.sign | wc -l

vi monitor.update.sh
vi nohup_update.sh

nohup sh nohup_update.sh >out.log 2>&1 &

