#!/bin/bash
#PBS -l nodes=1:ppn=2
#PBS -l mem=10G
#PBS -l walltime=60:00:00
#PBS -q small_ext
#PBS -N jupyter_nb

# q: medium_ext, legacy

ml singularity

export R_LIBS_USER=/home/lizhixin/softwares/R_lib_361
export R_LIBS=/home/lizhixin/softwares/R_lib_361
export PATH=/home/lizhixin/softwares/anaconda3/bin:$PATH
#export PATH=/home/lizhixin/softwares/singularity/bin:$PATH
#export PATH=/software/singularity/3.5.3/bin:$PATH

cd $PBS_O_WORKDIR
cd /home/lizhixin

# get tunneling info
XDG_RUNTIME_DIR=""
node=$(hostname -s)
user=$(whoami)
cluster="hpcf2.cgs.hku.hk"
port=17435

# print tunneling instructions jupyter-log
echo -e "
Command to create ssh tunnel:
ssh -N -f -L ${port}:${node}:${port} ${user}@${cluster}

Use a Browser on your local machine to go to:
localhost:${port}  (prefix w/ https:// if using password)
"

# Run Jupyter
# /home/lizhixin/softwares/anaconda3/bin/jupyter 

# source activate py38
# /home/lizhixin/softwares/anaconda3/envs/py38/bin/jupyter notebook --NotebookApp.iopub_data_rate_limit=1e10 --no-browser --port=${port} --ip=${node} &&\

source activate scenic_protocol
/home/lizhixin/softwares/anaconda3/envs/scenic_protocol/bin/jupyter-notebook --NotebookApp.iopub_data_rate_limit=1e10 --no-browser --port=${port} --ip=${node} &&\	

echo job-done

# qstat -f 359939.omics | grep vnode
# ssh -N -L 17435:hpch03:17435 lizhixin@hpcf2.cgs.hku.hk
# localhost:17435
