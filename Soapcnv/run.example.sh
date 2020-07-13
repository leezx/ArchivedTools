#!/bin/sh
#$ -S /bin/sh
#Version1.0	hewm@genomics.org.cn	2010-04-1
echo Start Time : 
date
/ifs1/RD/zhangbo/songchi/SFS_Rice/CNVCalc/bin/CNVCalc	-i	/ifs1/RD/zhangbo/songchi/SFS_Rice/CNVCalc/info/chr.info	-p	0.45	-P	0.6	-f	/panfs/RD/heweiming/NewRice/Reference/IRGSP_chromosomes_build04.fa	-D	/ifs1/RD/zhangbo/songchi/SFS_Rice/CNVCalc/Depth/rufipogon_YJ.depth	-o	/ifs1/RD/zhangbo/songchi/SFS_Rice/CNVCalc/CNV_OUT/rufipogon_YJ-result.list	
echo End Time : 
date
