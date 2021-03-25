
sample_list = []
#expression_dict = {}

outf = open("align_info_merged.csv", "w")
print("Sample",	"Total Reads", "Total Mapped Reads (%)","Unique Match(%)",	"Multi-position Match (%)",	"Total Unmapped Reads (%)", end="\n", sep=",", file=outf)

with open("map.list", "r") as listf:
	for one_file in listf:
		sample_name = one_file.strip().split("/")[-2]
		with open(one_file.strip(), "r") as inf:			
			count = 0
			for line in inf:
				line_list = line.strip().split()
				count += 1
				if count == 1:
					total_count = line_list[0]
				elif count == 3:
					unmap_ratio = line_list[1][1:-1]
				elif count == 4:
					map_ratio_1 = line_list[1][1:-1]
				elif count == 5:
					map_ratio_n = line_list[1][1:-1]
				elif count == 6:
					total_map_ratio = line_list[0]
			print(sample_name, total_count, total_map_ratio, map_ratio_1, map_ratio_n, unmap_ratio, sep=',', file=outf)

outf.close()
			



