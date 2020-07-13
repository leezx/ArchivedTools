inf = open("barcode_UMI.txt",'r')
d = {}
for line in inf:
	barcode, UMI = line.strip().split()
	if not barcode in d:
		d[barcode] = set()
		d[barcode].add(UMI)
	else:
		d[barcode].add(UMI)

with open("barcode_UMI.stat.out",'w') as outf:
	for key,value in d.items():
		print(key, len(value), file=outf)
