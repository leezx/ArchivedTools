# crontab can't work
# workdir=/home/lizhixin/project/scRNA-seq/rawData/May_2019/analysis_TPM/scripts
workdir=/home/lizhixin/project/scRNA-seq/rawData/Jul_2019/analysis_TPM/scripts

cd $workdir
while (true) 
do
 sh monitor.update.sh
 #date
 sleep 300
done
# nohup sh nohup_update.sh >out.log 2>&1 &
