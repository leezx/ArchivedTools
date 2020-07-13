source /ifs4/BC_RD/USER/lizhixin/script/env.sh
g++ FQ_CutIndex.cpp  -L../include/gzstream/ -lgzstream -lz  -static -o FQ_CutIndex
g++ MyFQ_Merge.cpp  -L../include/gzstream/ -lgzstream -lz  -static -o MyFQ_Merge

# modify func to main
# g++ complie, para is very important!!
