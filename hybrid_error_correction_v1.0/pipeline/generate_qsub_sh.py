#!/usr/bin/env python
# Author: LI ZHIXIN
"""
generate the shell script to be qsub, and auto qsub.
Usage: python <script> <in.bam.dir> <grid>
"""
import os
from subprocess import call
import sys

if len(sys.argv) -1 != 3:
        sys.exit(__doc__)

split_bam_dir, grid_P, grid_q = sys.argv[1:]
#split_bam_dir = "../split_bam/"
os.mkdir("correct_out")
os.mkdir("correct_shell")
os.mkdir("correct_stat")
bam_file_list = os.listdir(split_bam_dir)
qsub = "qsub -cwd -l vf=1g " + "-P %s -q %s"%(grid_P, grid_q)

sh_count = 0
for one_file in bam_file_list:
	sh_count += 1
	temp_sh_file = "correct_shell/run_" + str(sh_count) + ".sh"
	temp_bam_file = os.path.join(split_bam_dir, one_file)
	temp_out_file = "correct_out/corrected_" +str(sh_count) + ".fastq"
	temp_stat_file =  "correct_stat/stat_" +str(sh_count) + ".txt"
	outf = open(temp_sh_file, "w")
	head = "#!/bin/bash\necho ==========start at : `date` =========="
	tail = "echo ==========end  at : `date` =========="
	cmd = "python main_for_denovo_all_I.py %s %s %s" % (temp_bam_file, temp_out_file, temp_stat_file)
	print(head, cmd, tail, file=outf, sep='\n', end='\n')
	outf.close()

	qsub_cmd = "%s %s" % (qsub, temp_sh_file)
	qsub_cmd_list = qsub_cmd.split()
	call(qsub_cmd_list)
	
