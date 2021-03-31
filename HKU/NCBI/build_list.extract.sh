for one in `seq 1 81`
do
#echo $one
#echo ftp://ftp.ncbi.nih.gov/repository/dbEST/dbEST.reports.000000.${one}.gz >> ncbi.est.list
echo "zcat dbEST.reports.000000.${one}.gz | fgrep Organism: >> all.Organism" >> extract.sh
done
