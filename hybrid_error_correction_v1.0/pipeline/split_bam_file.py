#!/usr/bin/env python
# Author: LI ZHIXIN
"""
split bam to small bam file
Usage: python <script> <in.bam> <outdir>
"""
import pysam
import sys
import os

if len(sys.argv) -1 != 2:
	sys.exit(__doc__)

in_bam_file, absdir = sys.argv[1:]
#os.chdir(absdir)
outdir = os.path.join(absdir, 'split_bam')
os.mkdir(outdir)
# in_bam_file = "/ifs4/BC_RD/USER/lizhixin/my_project/20X_pacbio_chr22/call_variation/chr22_20X_filter_sortByName.bam"

in_bam = pysam.AlignmentFile(in_bam_file, "rb")

split_len = 15000

line_count = 0
count = 0
pre_reads_name = ""
temp_reads_name = ""

for line in in_bam:
	temp_reads_name = line.query_name
	if temp_reads_name != pre_reads_name:
		if line_count >= split_len*count:
			if count != 0:
				outf.close()
			out_bam_file = str(count) +".bam"
			out_bam_file = os.path.join(outdir, out_bam_file)
			outf = pysam.AlignmentFile(out_bam_file, "wb", template=in_bam)
			count += 1
	outf.write(line)
	pre_reads_name = temp_reads_name
	line_count += 1

in_bam.close()
outf.close()
