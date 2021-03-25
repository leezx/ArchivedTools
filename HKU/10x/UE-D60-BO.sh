#export PATH=/home/lizhixin/softwares/cellranger-2.1.1:$PATH
export PATH=/home/lizhixin/softwares/cellranger-3.1.0:$PATH

sampleName=UE-D60-BO-3
#appdir=/home/lizhixin/softwares/cellranger-2.1.1/
appdir=/home/lizhixin/softwares/cellranger-3.1.0/
workdir=/home/lizhixin/project/scRNA-seq/rawData/10x/Nov_2020/analysis

$appdir/cellranger count --id=${sampleName}_report \
                	--transcriptome=/home/lizhixin/databases/cellranger_ref/2019_Aug/refdata-cellranger-GRCh38-3.0.0 \
			--jobmode=local \
			--localcores=12 \
			--localmem=100 \
			--sample=${sampleName}-1,${sampleName}-2,${sampleName}-3,${sampleName}-4 \
			--fastqs=$workdir
			
# --csv=cellranger-tiny-bcl-simple-1.2.0.csv
# --csv=/home/lizhixin/softwares/cellranger-2.1.1/chromium-shared-sample-indexes-plate.csv \
# samplesheet
