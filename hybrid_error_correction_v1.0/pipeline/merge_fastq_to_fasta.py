#!/usr/bin/env python
# Author: LI ZHIXIN
"""
merge fastq to fasta, seq and qulity in one line, for pysam fetch
Usage: python <script> <in.fastq or fastq.gz> <outdir>
"""
import pysam
import sys
import os

if len(sys.argv) -1 != 2:
    sys.exit(__doc__)

in_file, outdir = sys.argv[1:]

#out_file = in_file.split(".")[0] + "_mergefastq.fasta"
out_file = os.path.join(outdir, "mergefastq.fasta")

#fastq_file = "/ifs4/BC_RD/USER/lizhixin/my_project/20X_pacbio_chr22/bayes_correct/PB_chr22_10X_random.fastq"
#out_file = "./mergefastq_20X.fasta"

fastq = pysam.FastxFile(in_file)
outf = open(out_file, 'w')

for line in fastq:
    name = '>' + line.name
    sequence = line.sequence
    quality = line.quality
    merge = sequence + quality
    print(name, merge, file=outf, sep='\n', end='\n')
    # break

fastq.close()
outf.close()
