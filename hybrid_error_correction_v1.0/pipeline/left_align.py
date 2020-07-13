#!/usr/bin/env python3
""" left align indels
Usage: python <script> <in.bam>  <out.bam>
"""
import BioUtil
# import pysam
# from fasta import fastaReader
import argparse
from cigar import CIGAR
import sys
from collections import defaultdict, namedtuple, deque
import warnings
import logging as log
import shlex
from itertools import repeat
log.basicConfig(level=log.INFO)

debug = not True
if debug:
    log.getLogger().setLevel(log.DEBUG)

def main():
    parser = argparse.ArgumentParser(
        description="left align indels from bam file.",
        epilog="NOTE: this script will remove MD tags from bam file, "
        "please regenerate them using `samtools calmd' if needed")
    parser.add_argument("inbam", metavar="in.bam")
    parser.add_argument("outbam", metavar = "out.bam")
    parser.add_argument("-M", choices=["M", "="], default="M",
            help = "Match character in CIGAR, default:M")
    parser.add_argument("--ref", "-r", metavar="ref.fa", required =True,
            help = "reference, required")
    parser.add_argument("--merge-adjacent-indel", "-m", dest="merge_adj", action="store_true",
            help = "merge adjacent INS and DEL, resulting a (mis)match")
    args = parser.parse_args()

    if args.M == "M":
        args.EQUAL = args.DIFF = CIGAR.MATCH
    else:
        args.EQUAL, args.DIFF = CIGAR.EQUAL, CIGAR.DIFF
    args.MATCH_TYPES = set([args.EQUAL, args.DIFF])
    
    if args.ref:
        ref = BioUtil.cachedFasta(args.ref, trans=str.upper)
    else:
        ref = None

    bam = BioUtil.samFile(args.inbam, 'rb')
    header = bam.header
    # print(header)
    header['PG'].append( {
        'ID':'left_align', 
        'PN': 'left_align.py',
        'CL': " ".join(map(shlex.quote, sys.argv)) 
        })
    out = BioUtil.samFile(args.outbam, 'wb', header=header)
#    counter = log.recordLogger(step=10000)
#    counter = log.periodLogger(period=60, format="{:,} records has processed")

    count = 0
    for rec in bam:
        out.write(modify_record(rec, ref, args))
        count+= 1
#        counter.update(count)
    bam.close()
    out.close()
    log.info("DONE\nDONE")


def modify_record(rec, ref, args):
    if rec.is_unmapped:
        return rec
    if ref is not None:
        ref = ref[rec.reference_name][rec.reference_start:rec.reference_end]
    else:
        ref =  rec.get_reference_sequence()
    ref_p = 0
    read = rec.query_sequence
    read_p = 0
    chars = deque() # cigar characters 
    for op, length in rec.cigartuples:
        if op == CIGAR.HARD_CLIP:
            para = (False, 0, 0) # is_indel, ref_p increase, read_p increase
        elif op == CIGAR.SOFT_CLIP:
            para = (False, 0, length)
        elif op in args.MATCH_TYPES: 
            para = (False, length, length)
        elif  op == CIGAR.INS:
            para = (True, 0, length)
        elif op == CIGAR.DEL:
            para = (True, length, 0)
        else:
            warnings.warn("Cannot handle operation type: %s %s %s" %
                    (rec.query_name, read_p, CIGAR.get_name(op)))
            para = (False, length, length)

        is_indel, ref_inc, read_inc = para
        if is_indel: 
            chars = left_align(chars, op, length, 
                    ref, read, ref_p, read_p, args)
        else:
            chars.extend(repeat(op, length))
        ref_p += ref_inc
        read_p += read_inc

    if ref_p != rec.reference_end - rec.reference_start or read_p != rec.query_length:
        warnings.warn("%s: length not match pysam result: "
                "ref %s vs %s read %s vs %s" % 
                (rec.query_name, ref_p, rec.reference_end, 
                    read_p, rec.query_length))
    rec.cigartuples = run_length_encode(chars)
    if rec.has_tag('MD'):
        rec.set_tag('MD', None)
    return rec

def left_align(chars, op, length, ref, read, ref_p, read_p, args):
    if op == CIGAR.INS:
        ref_inc, read_inc = 0, length
        opposite_op = CIGAR.DEL
    elif op == CIGAR.DEL:
        ref_inc, read_inc = length, 0
        opposite_op = CIGAR.INS
    ref_last = ref_p + ref_inc - 1
    read_last = read_p + read_inc - 1
    tail = deque() # shifted-right cigar-chars
    while ref_last >= 0 and read_last >= 0 and len(chars) > 0:
        if chars[-1] in args.MATCH_TYPES and read[read_last] == ref[ref_last]: 
            # could shift, do not pass through mutations
            chars.pop()
            tail.appendleft(args.EQUAL)
            ref_last -= 1
            read_last -= 1
        elif chars[-1] == op: 
            # near another indel, merge and go through
            # the last base position do note need to change
            # as the meet one is before the processing one
            chars.pop()
            length += 1
        elif args.merge_adj and chars[-1] == opposite_op and length > 0:
            # meet the opposite op, merge to meet sam specification
            # ins + del resulting a (mis)match
            chars.pop()
            if ((op == CIGAR.INS and 
                    read[read_last - length + 1] == ref[ref_last]) or
                (op == CIGAR.DEL and 
                    read[read_last] == ref[ref_last - length + 1]) ):
                chars.append(args.EQUAL)
            else:
                chars.append(args.DIFF) 
            length -= 1

        else:
            break
    chars.extend(repeat(op, length))
    chars.extend(tail)
    return chars

def run_length_encode(seq):
    prev = None
    count = 1
    lst = []
    for character in seq:
        if character != prev:
            if prev is not None:
                entry = (prev,count)
                lst.append(entry)
            count = 1
            prev = character
        else:
            count += 1
    else:
        entry = (prev,count)
        lst.append(entry)
    return lst


if __name__ == '__main__':
    main()

    

