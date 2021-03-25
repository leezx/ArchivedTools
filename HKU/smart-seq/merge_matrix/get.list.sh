

ls ../results/*/*.genes.results |  sed "s:^:`pwd`/: " > exp.list
ls ../results/*/*.Map2GenomeStat.xls |  sed "s:^:`pwd`/: " > map.list
ls ../results/*/*.filter.stat.xls |  sed "s:^:`pwd`/: " > qc.list

cp exp.list map.list qc.list ~/project/scRNA-seq/rawData/merge_all/IMR90_UE_ENCC/

cat */exp.list > all.exp.list
cat */map.list > all.map.list
cat */qc.list > all.qc.list

