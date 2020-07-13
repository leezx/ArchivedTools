# Author: LI ZHIXIN
# E-mail: lizhixin@genomics.cn
# Date: 2017-7-24

1. software
install bowtie-1.1.2
ln -s bowtie-1.1.2/bowtie-build to ./bin
ln -s bowtie-1.1.2/bowtie to ./bin
make sure bowtie-1.1.2 is in your $PATH.

2.python3 and its packages
install python3
python3 -m pip install pysam gzip subprocess collections

3.library
SE100
fq1:100
fq2:10+18+10+5+10(UMI)
