import os

# outdir = "/home/lizhixin/project/scRNA-seq/rawData/May_2019/analysis_TPM/results"
outdir = "/home/lizhixin/project/scRNA-seq/rawData/Jul_2019/analysis_TPM/results"
tail_file = "scRNA_seq_filter_align_count.matrix.sh"
fastq_list = "all.sample.csv"
cpu = 2

work_dir = os.path.abspath('.') + "/"
file_list = work_dir + fastq_list
tail_content = ""
with open(work_dir+tail_file,"r") as tailf:
	for line in tailf:
		tail_content += line

with open(file_list, "r") as inf:
	for line in inf:
		line_list = line.strip().split(",")
		sampleName, raw_fq1, raw_fq2 = line_list[0], line_list[1], line_list[2]
		fq_dir = "/".join(raw_fq1.split("/")[:-1])
		with open(work_dir+sampleName+".sh","w") as outf:
			print("#!/bin/bash", file=outf)
			print("# Written By Zhixin Li.", file=outf)
			print("sName="+sampleName, file=outf)
			print("raw_fq1="+raw_fq1, file=outf)
			print("raw_fq2="+raw_fq2, file=outf)
			print("fq_dir="+fq_dir, file=outf)
			print("outdir="+outdir, file=outf)
			print("cpu="+str(cpu), file=outf)
			print(tail_content, file=outf)
		# break
