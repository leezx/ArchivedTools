# source activate splicing

# hg38
index=/home/lizhixin/references/SUPPA2/ref/GRCh38/gencode.v37.transcripts.salmon.index/
# hg19
# index=/home/lizhixin/references/SUPPA2/ref/hg19/Ensembl_hg19_salmon_index/

# need to merged fastq files
for i in `ls merged.fastq/*.list0*`
#for i in `ls merged.fastq/{IMR90.list*,17C8.list*}`
do
        echo $i &&\
        cut -d, -f2 $i | xargs zcat > ${i}_1.fastq &&\
        cut -d, -f3 $i | xargs zcat > ${i}_2.fastq &&\
	# gzip fastq/${i}_1.fastq fastq/${i}_2.fastq &&\
	/home/lizhixin/softwares/anaconda3/envs/splicing/bin/salmon quant -i $index  -l ISF --gcBias -1 ${i}_1.fastq -2 ${i}_2.fastq -p 10 -o ${i}_output &&\
	rm ${i}_1.fastq ${i}_2.fastq &&\
        echo "done"
done

