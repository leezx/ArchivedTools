rm database.json
rm *.sign
monitor qsub -f file.list
monitor stat

cp /home/lizhixin/project/scRNA-seq/rawData/Apr_2018/analysis_TPM/tools/monitor.update.sh ./
# add crontab 
crontab -e
# */1 * * * * cd /home/lizhixin/project/monitor/test && sh /home/lizhixin/project/monitor/test/monitor.update.sh
*/6 * * * * cd /home/lizhixin/project/scRNA-seq/batch_1/analysis/scripts && sh /home/lizhixin/project/scRNA-seq/batch_1/analysis/scripts/monitor.update.sh

ls *.sign | wc -l
