# monitor update >monitor.log 2>&1
# workdir=/home/lizhixin/project/scRNA-seq/rawData/May_2019/analysis_TPM/scripts
workdir=/home/lizhixin/project/scRNA-seq/rawData/Jul_2019/analysis_TPM/scripts

cd $workdir
echo "
======>">>monitor.log
date >>monitor.log
python3 /home/lizhixin/project/monitor/monitor.V2/monitor.py update >>monitor.log 2>&1
