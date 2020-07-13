/home/heweiming/bin/Tools/iTools Fqtools cutIndex -InFq /ifs4/BC_RD/PROJECT/F16RD11042/lizhixin/prj/single_Cell/2_barcode_split/CL200020292_L01_read_2.fq.gz -OutFq barcode1.fq.gz -StartCut 1 -LengthCut 10
/home/heweiming/bin/Tools/iTools Fqtools cutIndex -InFq /ifs4/BC_RD/PROJECT/F16RD11042/lizhixin/prj/single_Cell/2_barcode_split/CL200020292_L01_read_2.fq.gz -OutFq barcode2.fq.gz -StartCut 29 -LengthCut 10
/home/heweiming/bin/Tools/iTools Fqtools cutIndex -InFq /ifs4/BC_RD/PROJECT/F16RD11042/lizhixin/prj/single_Cell/2_barcode_split/CL200020292_L01_read_2.fq.gz -OutFq UMI.fq.gz -StartCut 44 -LengthCut 10

/home/heweiming/bin/Tools/iTools Formtools Fq2Fa -InFq UMI.fq.gz -OutPut UMI.fasta
