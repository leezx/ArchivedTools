# /home/lizhixin/project/scRNA-seq/rawData/smart-seq/archive_20201222/all.sample.csv

cat all.sample.csv | grep "10c2" > 10c2.list
cat all.sample.csv | grep "17C8" > 17C8.list
cat all.sample.csv | grep "1C11" > 1C11.list
cat all.sample.csv | grep "20c7" > 20c7.list
cat all.sample.csv | grep "23C9" > 23C9.list
cat all.sample.csv | grep "3C15" > 3C15.list
cat all.sample.csv | grep "5c3" > 5c3.list
cat all.sample.csv | grep "6c5" > 6c5.list
cat all.sample.csv | grep "^IMR90" > IMR90.list
cat all.sample.csv | grep "IMR-N_Diff-D20" > IMR-N_Diff-D20.list
cat all.sample.csv | grep "IMR-N_Diff-D40" > IMR-N_Diff-D40.list
cat all.sample.csv | grep "iPSC-IMR90" > iPSC-IMR90.list
cat all.sample.csv | grep "iPSC-UE" > iPSC-UE.list
cat all.sample.csv | grep "^UE" | grep -v "N_Diff" > UE.list
cat all.sample.csv | grep "UE-N_Diff_D20" > UE-N_Diff_D20.list
cat all.sample.csv | grep "UE-N_Diff-D40" > UE-N_Diff-D40.list

split -d -n l/5 10c2.list 10c2.list
split -d -n l/5 17C8.list 17C8.list
split -d -n l/5 1C11.list 1C11.list
split -d -n l/5 20c7.list 20c7.list
split -d -n l/5 23C9.list 23C9.list
split -d -n l/5 3C15.list 3C15.list
split -d -n l/5 5c3.list 5c3.list
split -d -n l/5 6c5.list 6c5.list
split -d -n l/5 IMR90.list IMR90.list
split -d -n l/5 IMR-N_Diff-D20.list IMR-N_Diff-D20.list
split -d -n l/5 IMR-N_Diff-D40.list IMR-N_Diff-D40.list
split -d -n l/5 iPSC-IMR90.list iPSC-IMR90.list
split -d -n l/5 iPSC-UE.list iPSC-UE.list
split -d -n l/5 UE.list UE.list
split -d -n l/5 UE-N_Diff_D20.list UE-N_Diff_D20.list
split -d -n l/5 UE-N_Diff-D40.list UE-N_Diff-D40.list
