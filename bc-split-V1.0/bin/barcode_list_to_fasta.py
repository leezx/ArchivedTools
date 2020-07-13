#!/usr/bin/env python3
# Author: LI ZHIXIN
""" 
format barcode.list to fasta file!
Usage: python3 <script> <barcode.list>
"""
import sys

if len(sys.argv) - 1 != 1:
	sys.exit(__doc__)

infile = sys.argv[1]

inf = open(infile,'r')
outf = open("barcode.fasta", 'w')
for line in inf:
	barcode, id = line.strip().split()
	print(">"+id, file=outf)
	print(barcode, file=outf)

inf.close()
outf.close()

