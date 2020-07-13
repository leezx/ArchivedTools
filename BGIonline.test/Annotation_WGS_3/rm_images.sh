docker ps -a |grep "Exit"|grep annotation|less -SN
docker ps -a |grep "Exit"|grep annotation_wgs:1.0 | awk '{print $1}' | xargs docker rm
