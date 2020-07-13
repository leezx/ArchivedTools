#!/usr/bin/env python

import os
outf = open("allDependent.txt", "w")
# modify_allDep.py

job_list = set()

with open("/ifs4/BC_RD/PROJECT/RD_LZX_correction/prj/pymonitor/test/outdir/list/allDependent.txt", "r") as inf:
    mem = "0.1G"
    for line in inf:
        former, later = line.split()
        former = former.split(":")[0]
        later = later.split(":")[0]
        job_list.add(former)
        job_list.add(later)
        print("%s:%s\t%s:%s"%(former,mem,later,mem), file=outf)
    outf.close()


for sh in job_list:
    if not os.path.exists(sh):
        continue
    contents = ["#!/bin/bash", "echo Still_waters_run_deep > %s.sign"%sh]
    add_sleep = "\npython /ifs4/BC_RD/PROJECT/RD_LZX_correction/prj/pymonitor/test/sleep.py\n"
    with open(sh, "w+") as inf:
        for line in inf:
            contents.append(line.strip())
        print(contents[0], add_sleep, contents[-1], file=inf, sep='\n')
    #break

