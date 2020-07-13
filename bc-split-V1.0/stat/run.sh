cat fastq_head.txt | cut -d# -f2 | cut -d/ -f1 | sort | uniq -c > barcode_reads.out

