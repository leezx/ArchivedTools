[Docker](https://www.docker.com/)

```shell
#!/bin/bash
file=$1
id=$2
tar -cv $file | docker exec -i $id tar x -C /var/data
```



```shell
#!/bin/bash

# prepare file
cp Dockerfile sources.list timezone ./

# revise Dockerfile

# prepare file for docker
bo download -p  /lizhixin/file/trans.tar.gz wes_test ./
bo download -p  /lizhixin/file/trans.tar.gz wes_test ./

# build docker
# newest 90117a5071ee
#docker build -t bamstat:1.0 .
#docker build -t fqfilter:1.0 .
#docker build -t annotation_wgs:1.0 .
#docker build -t annotation_wgs_2:1.0 .
docker build -t annotation_wgs_3:1.0 .

docker images | grep bamstat | less # check

# log into local docker
#docker run -it bamstat:1.0
#docker run -it fqfilter:1.0
#docker run -it annotation_wgs:1.0
#docker run -it annotation_wgs_2:1.0
docker run -it annotation_wgs_3:1.0

# revise and commit
#docker commit a916ba163d5c bamstat:1.0
#docker commit 7fb6ac4b3c02 fqfilter:1.0
#docker commit ded2b32bacf9 annotation_wgs:1.0
#docker commit d40d65759062 annotation_wgs_2:1.0
docker commit d40d65759062 annotation_wgs_3:1.0

# push to genedock
docker login cn-beijing-registry.genedock.com
# admin@wangxuebin
# bgi_1104
#docker tag bamstat:1.0 cn-beijing-registry.genedock.com/lizhixin/bamstat:1.0
#docker push cn-beijing-registry.genedock.com/lizhixin/bamstat:1.0  # error
docker tag annotation_wgs_2:1.0 cn-beijing-registry.genedock.com/wangxuebin/annotation_wgs:1.0
docker tag cn-beijing-registry.genedock.com/wangxuebin/reportwgs:1.0 cn-shenzhen-registry.genedock.com/wangxuebin/reportwgs:1.0
docker push cn-beijing-registry.genedock.com/wangxuebin/annotation_wgs:1.0
```

[genedock](https://www.genedock.com/)

生物云计算领先企业，最接近底层docker的设计。

```shell
# upload file to genedocker
genedock config
#GeneDock provides [1shenzhen (Default), 2qingdao, 3beijing] regions.
#Please enter the index of your region [1 to 3]:3
#Please enter your accessid[Required]: KMPLfB8fQAvyvynpDwPxsQ==
#Please enter your accesskey[Required]: pu/qrzLBKi1EqL05qaVJPLmdHiE=
#Please enter the account_alias:  LZX
#Are you switching to account_alias:[LZX] now? [YES/NO]: y
#Config sucessfully! The account_name is: wangxuebin and the user_name is: admin
# file
genedock upload /mnt2/BC_RD/lizhixin/AnnoDB.tar /home/lizhixin/AnnoDB.tar
# dir
genedock upload ./test-data /home/lizhixin/test-data

# cp file from docker to local
docker cp 8079409ec2e8:/var/data/test-data ./
```

[BGI Online](https://www.bgionline.cn/index.html)

半调子，好在后台很硬，不愁没有业务。







