#!/usr/bin/env python3
# Author: LI ZHIXIN
# E-mail: lizhixin@genomics.cn
# Date: 2017-7-24
""" 
This program is developed for BGI research institute by LIZHIXIN from BGI bc_rd.
Split 2 barcodes and UMI, output integrated split_read.1.fq
--------------------------------------------------------------------------------
Usage: python3 <script> <reads1.fastq> <reads2.fastq> <barcode.fasta>
"""
import sys
import gzip
from subprocess import call
import pysam
from collections import OrderedDict

if len(sys.argv) - 1 != 3:
	sys.exit(__doc__)

read_1, read_2, barcode_fasta = sys.argv[1:]

def extract_2barcode_UMI(read_2):
	""""A shell wrapper"""
	cmd = "sh %s/extract_2barcode_UMI.sh %s"%(sys.path[0], read_2)
	cmd_list = cmd.split()
	call(cmd_list)
	# python is too slow!!!
	# outf1 = open("barcode1.fasta", "w")
	# outf2 = open("barcode2.fasta", "w")
	# outf3 = open("UMI.fasta", "w")
	# inf = gzip.open(read_2)
	# count =  1
	# for line in inf:
	# 	line = line.decode().strip()
	# 	if count % 4 == 2:
	# 		#print(line[:10],line[10:28],line[28:38],line[38:43],line[43:53],sep=' ')
	# 		print(line[:10],file=outf1)
	# 		print(line[28:38],file=outf2)
	# 		print(line[43:53],file=outf3)
	# 	elif count % 4 == 1:
	# 		print(">"+line[1:].split('/')[0],file=outf1)
	# 		print(">"+line[1:].split('/')[0],file=outf2)
	# 		print(">"+line[1:].split('/')[0],file=outf3)
	# 	count += 1
	# inf.close()
	# outf1.close()
	# outf2.close()
	# outf3.close()

def filter_combine_2barcode(barcode1="barcode1.fasta",barcode2="barcode2.fasta",barcode_ref="barcode.fasta"):
	""""A shell wrapper"""
	cmd = "sh %s/align_filter.sh"%sys.path[0]
	cmd_list = cmd.split()
	call(cmd_list)

def transform_reads_barcode_to_fasta_bak(reads_barcode="reads_barcode.txt", UMIfile="UMI.fasta"):
	barcode_file = open(reads_barcode, 'r')
	outf = open("reads_barcode.fasta", 'w')
	UMIf = pysam.FastaFile(UMIfile)
	#barcode_count_dict = OrderedDict()
	barcode_count_dict = []
	barcode_count = 1
	for line in barcode_file:
		seq_name, barcode_name = line.strip().split()
		seq_name = seq_name.split('/')[0]
		if not barcode_name in barcode_count_dict:
			#barcode_count_dict[barcode_name] =  barcode_count
			barcode_count_dict.append(barcode_name)
			barcode_count += 1
		#print(">"+seq_name, barcode_name+"#"+str(barcode_count_dict[barcode_name])+"#"+UMIf.fetch(seq_name+"/2"), file=outf, sep='\n')
		print(">"+seq_name, barcode_name+"#"+str(barcode_count_dict.index(barcode_name)+1)+"#"+UMIf.fetch(seq_name+"/2"), file=outf, sep='\n')
	barcode_file.close()
	outf.close()
	UMIf.close()
	with open("2barcodes.rank.txt",'w') as rangef:
		#for i,one in barcode_count_dict.items():
		for i,one in enumerate(barcode_count_dict):
			print(i+1,one,file=rangef)

def transform_reads_barcode_to_fasta(reads_barcode="reads_barcode.txt", UMIfile="UMI.fasta", uniq_bc="uniq.barcode.txt"):
	barcode_count_dict = {}
	barcode_count = 1
	with open(uniq_bc, 'r') as uniq_bcf:
		for line in uniq_bcf:
			barcode_count_dict[line.strip()] = barcode_count
			barcode_count += 1
	barcode_file = open(reads_barcode, 'r')
	outf = open("reads_barcode.fasta", 'w')
	UMIf = pysam.FastaFile(UMIfile)
	#barcode_count_dict = OrderedDict()
		
	for line in barcode_file:
		seq_name, barcode_name = line.strip().split()
		# seq_name = seq_name.split('/')[0]
		# if not barcode_name in barcode_count_dict:
		# 	#barcode_count_dict[barcode_name] =  barcode_count
		# 	barcode_count_dict.append(barcode_name)
		# 	barcode_count += 1
		#print(">"+seq_name, barcode_name+"#"+str(barcode_count_dict[barcode_name])+"#"+UMIf.fetch(seq_name+"/2"), file=outf, sep='\n')
		print(">"+seq_name, barcode_name+"#"+str(barcode_count_dict[barcode_name])+"#"+UMIf.fetch(seq_name), file=outf, sep='\n')
	barcode_file.close()
	outf.close()
	UMIf.close()
	barcode_count_dict = {}
	# with open("2barcodes.rank.txt",'w') as rangef:
	# 	#for i,one in barcode_count_dict.items():
	# 	for i,one in enumerate(barcode_count_dict):
	# 		print(i+1,one,file=rangef)

def merge_2barcode_UMI_to_read1_bak(read_1, reads_barcode="reads_barcode.fasta"):
	# UMIf = pysam.FastaFile(UMIfile)
	#barcode_file = open(reads_barcode, 'r')
	barcode_file = pysam.FastaFile(reads_barcode)
	# Take up too much memory
	# barcode_dict = OrderedDict()
	# barcode_count_dict = OrderedDict()
	# barcode_count = 1
	# for line in barcode_file:
	# 	seq_name, barcode_name = line.strip().split()
	# 	barcode_dict[seq_name.split('/')[0]] = barcode_name
	# 	if not barcode_name in barcode_count_dict:
	# 		barcode_count_dict[barcode_name] =  barcode_count
	# 		barcode_count += 1
	inf = gzip.open(read_1)
	outf = open("split_read.1.fq", 'w')
	count =  1
	flag = 0
	barcode_list = set(barcode_file.references) # fucking slow!!!
	for line in inf:
		content = line.decode('ascii').strip()
		if count % 4 == 1:
			name = content.split('/')[0]
			if not name[1:] in barcode_list:
				flag = 0
			else:
				flag = 1
			if flag == 1:
				barcode_name, barcode_count, UMI = barcode_file.fetch(name[1:]).split('#')
				#new_name = name  + "#" + barcode_dict[name[1:]] + "/1\tUMI:" + UMIf.fetch(name[1:]) +"\t"+ str(barcode_count_dict[barcode_dict[name[1:]]]) + "\t" + "1"
				new_name = name  + "#" + barcode_name + "/1\tUMI:" + UMI + "\t" + barcode_count + "\t" + "1"
				# new_name = barcode_file.fetch(name[1:])
				# print(new_name)
				print(new_name, file=outf)
		else:
			if flag == 1:
				print(content, file=outf)
		count += 1
	inf.close()
	barcode_file.close()
	outf.close()
	# UMIf.close()

def merge_2barcode_UMI_to_read1(read_1):
	""""A shell wrapper"""
	cmd = "sh %s/merge.sh %s"%(sys.path[0], read_1)
	cmd_list = cmd.split()
	call(cmd_list)

def clean_file():
	clean_cmd = "sh %s/clean_files.sh"%sys.path[0]
	cmd = "gzip split_read.1.fq"
	cmd_list = cmd.split()
	call(cmd_list)
	print("\n--------------------------\nIf you want to clean files, please run \n%s\n--------------------------\n"%clean_cmd)

if __name__=='__main__':
	print("Work starting...")
	extract_2barcode_UMI(read_2)
	filter_combine_2barcode()
	merge_2barcode_UMI_to_read1(read_1)
	clean_file()
	print("Work done!!!")	
