#!/usr/bin/env python3
# Author: LI ZHIXIN
"""
Usage: python3 <script> <old.result> <new.result>
"""
import sys

if len(sys.argv) - 1 != 2:
	sys.exit(__doc__)

infile1, infile2 = sys.argv[1:]
inf1 = open(infile1,'r')
inf2 = open(infile2,'r')
#inf1 = open("final_barcode.txt",'r')
#inf2 = open("old.barcode.txt", 'r')

set1 = set()
set2 = set()

for line in inf1:
	line=line.strip()
	set1.add(line)

for line in inf2:
	line=line.strip()
	set2.add(line)

inf1.close()
inf2.close()

with open("stat.out", 'w') as outf:
	print("old:", len(set1),file=outf)
	print("new:", len(set2), file=outf)
	print("overlap:", len(set1&set2), file=outf)
