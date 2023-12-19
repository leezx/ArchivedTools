cd /home/lizhixin/project/scRNA-seq/rawData/Oct_2018/NganE_scRNA_SS-180801-04a/primary_seq

ls *_1.fastq.gz | sed "s:^:`pwd`/: " > ../read_1
cd ..
cp read_1 read_2

less read_1 | cut -f10 -d'/' > sample.name
vi sample.name
# vim
# :%s/foo/bar/g
# %s/_1\.fastq\.gz//g

vi read_2
# don't use read_2, disorder!!!
# notepad++ _1. ==> _2.
# vim
# %s/_1\./_2\./g
paste sample.name read_1 read_2 -d',' > all.sample.csv
# test
# cat all.sample.csv | cut -f2 -d, | xargs ls | grep such

# rename sample name
# Treatment-TF/Histone-Replicate
# Don't use Excel to edit/save csv files, it will add special characters!!!!!!!!


#####################################################
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

