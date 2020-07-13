# /mnt/BC_RD/lizhixin/Tools/reportwgs-799016a4-7242-4616-bf02-7cc1ba7b3aa2/reportwgs
# /mnt/BC_RD/wangxuebin/Tools/reportwgs-799016a4-7242-4616-bf02-7cc1ba7b3aa2/reportwgs
# /ifs4/BC_RD/USER/wangxb/BGIonline/WGS/wholeTest/WGSbingxing0322_1_output/UPLOAD/result/

# 访问地址39.108.110.188 
# 开发目录 /mnt/, 6T空间
# 1.5开发机旧数据目录 /old_data


docker images > images

docker run -t -i 10.224.1.55:5000/default_user/reportwgs:b42aae84ea6bcc3f /bin/bash
docker run -t -i cn-beijing-registry.genedock.com/wangxuebin/reportwgs:1.0 /bin/bash
docker run -t -i cn-shenzhen-registry.genedock.com/wangxuebin/reportwgs:1.0 /bin/bash
docker commit 93bc69e78376 cn-shenzhen-registry.genedock.com/wangxuebin/reportwgs:1.0


docker login cn-beijing-registry.genedock.com
docker login cn-shenzhen-registry.genedock.com
# admin@wangxuebin
# bgi_1104

docker tag 10.224.1.55:5000/default_user/reportwgs:146f4bc456347488 cn-beijing-registry.genedock.com/wangxuebin/reportwgs:1.0

docker push cn-beijing-registry.genedock.com/wangxuebin/reportwgs:1.0
docker push cn-shenzhen-registry.genedock.com/wangxuebin/reportwgs:1.0

perl /opt/bin/generateDataSummary_WGS.pl -d ./result -o ./ -i 30
perl /opt/bin/generateArf_WGS.pl -d ./result -o ./ -p BGISEQ
perl /opt/bin/generateArf_WGS_CN.pl -d ./result -o ./ -p BGISEQ
cp /opt/bin/report.txt ./UPLOAD/report.txt
/opt/bin/arf2html317.pl -i ./UPLOAD/arf -d ./UPLOAD -t /opt/bin/template -o ./
cp -r ./UPLOAD/result/* ./report/result
cp report/*.pdf ./
zip -q -r report.zip report
echo ProjectNo SubProjectCode\twww.genedock.com\tOperatorName email group\t30 > basic_info_WGS

perl /opt/bin/QA_WGS_forBGIonline.pl -l rawData_list -info basic_info_WGS -s hg19 -type pe101 -I -P -CL -d result -o ./QA_out

# sh push.sh test-data b3f9cc956fc3
# perlcc -B arfPreCheck.pl -o arfPreCheck
# /usr/local/lib/perl/5.18.2  # lib path
# apt-get install g++
# apt-get install libperl-dev  # for ld error
# Global symbol "%Config" requires explicit package name at /bin/perlcc line 258.  # replicate error



#!/bin/bash
file=$1
id=$2
tar -cv $file | docker exec -i $id tar x -C /var/data


tar zxvf {% for item in inputs.results %}{% if loop.first %}{{ item.path }}{% else %}{{ item.path }}{% endif %}{% endfor %}
perl /opt/bin/generateDataSummary_WGS.pl -d ./result -o ./ -i {{ parameters.depth }}
perl /opt/bin/generateArf_WGS.pl -d ./result -o ./ -p {{ parameters.p }}
perl /opt/bin/generateArf_WGS_CN.pl -d ./result -o ./ -p {{ parameters.p }}
cp /opt/bin/report.txt ./UPLOAD/report.txt
/opt/bin/arf2html317.pl -i ./UPLOAD/arf -d ./UPLOAD -t /opt/bin/template -o ./
cp -r ./UPLOAD/result/* ./report/result
cp report/*.pdf ./
zip -q -r report.zip report
echo {{ parameters.ProjectID }}\twww.genedock.com\t{{ parameters.analysist }}\t{{ parameters.depth }} > basic_info_WGS
#perl /opt/bin/QA_WGS_forBGIonline.pl -l rawData_list -info basic_info_WGS -s hg19 -type pe101 -I -P -CL -d result -o ./QA_out
cp report.zip {% for item in outputs.report %}{% if loop.first %}{{ item.path }}{% else %}{{ item.path }}{% endif %}{% endfor %} 
cp report_cn.pdf {% for item in outputs.report_pdf_cn %}{% if loop.first %}{{ item.path }}{% else %}{{ item.path }}{% endif %}{% endfor %} 
cp report_en.pdf {% for item in outputs.report_pdf_en %}{% if loop.first %}{{ item.path }}{% else %}{{ item.path }}{% endif %}{% endfor %}  