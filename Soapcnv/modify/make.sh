#!/bin/sh
#$ -S /bin/sh
#Version1.0	hewm@genomics.org.cn	2012-06-09
echo Start Time : 
date
g++	finx.hewm.cpp	-lpthread	-lboost_thread	-lm	-lz	-lgzstream	-L	../../Genotype/Test/	-lpthread	-lboost_thread	-ldl	-lpthread	-I	/opt/blc/boost_1_44_0/include/boost/	
echo End Time : 
date
