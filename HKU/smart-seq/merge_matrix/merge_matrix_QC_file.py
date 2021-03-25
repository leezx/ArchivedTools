

outf = open("QC_info_merged.csv", "w")
#print("Sample",	"Clean Read1 Q20(%) >= 95",	"Clean Read1 Q30(%) >= 90",	"Clean Reads >= 10 (M)", "Gene Unique Mapping Ratio(%) >= 80", "Genome Mapping Ratio(%) >= 50", end="\n", sep=",", file=outf)
print("Sample",	"Total Raw Reads(Mb)", "Total Clean Reads(Mb)", "Total Clean Bases(Gb)", "Clean Reads Q20(%)", "Clean Reads Q30(%)", "Clean Reads Ratio(%)", "GC(%)", end="\n", sep=",", file=outf)

with open("qc.list", "r") as listf:
	for one_file in listf:
		sample_name = one_file.strip().split("/")[-2]
		with open(one_file.strip(), "r") as inf:			
			count = 0
			for line in inf:
				line_list = line.strip().split()
				count += 1
				if count == 2:
					total_raw_reads_count = line_list[3]
					total_clean_reads_count = line_list[4]
				elif count == 3:
					total_clean_base = line_list[3]
				elif count == 6:
					GC1 = line_list[4]
				elif count == 7:
					GC2 = line_list[4]
				elif count == 8:
					raw_q1_q20 = line_list[3]
					clean_q1_q20 = line_list[4]
				elif count == 9:
					raw_q2_q20 = line_list[3]
					clean_q2_q20 = line_list[4]
				elif count == 10:
					raw_q1_q30 = line_list[3]
					clean_q1_q30 = line_list[4]
				elif count == 11:
					raw_q2_q30 = line_list[3]
					clean_q2_q30 = line_list[4]
				
			print("%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f"%(sample_name, int(total_raw_reads_count)/1000000, \
				int(total_clean_reads_count)/1000000, int(total_clean_base)/1000000000, \
			(float(clean_q1_q20)+float(clean_q2_q20))/2, (float(clean_q1_q30)+float(clean_q2_q30))/2, \
			int(total_clean_reads_count)/int(total_raw_reads_count)*100, (float(GC1)+float(GC2))/2), sep=',', file=outf)

outf.close()
			



