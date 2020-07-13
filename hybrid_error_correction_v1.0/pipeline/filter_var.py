#!/usr/bin/env python3
""" filter out variants above quality 30
Usage: python <script> <in.raw.vcf> <out.filtered.vcf>
"""
import BioUtil
import sys
if len(sys.argv) -1 != 2:
    sys.exit(__doc__)
infile, outfile = sys.argv[1:]
input = BioUtil.vcfFile(infile)
output = BioUtil.vcfFile(outfile, 'w', template=input)
for rec in input:
    mut = rec.num_hom_ref != rec.num_called
    hq = rec.QUAL is not None and rec.QUAL >= 30 
    if mut and hq:
        output.write_record(rec)
input.close()
output.close()

