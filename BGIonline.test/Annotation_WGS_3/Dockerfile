#Dockerfile to install Bio apps (include BWA)
#test for liuxuanzhu
#http://bio-bwa.sourceforge.net/
#https://github.com/lh3/bwa

FROM ubuntu:14.04
MAINTAINER Li Ming, liming@genedock.com
MAINTAINER Wang Huanwei, wanghuanwei@genedock.com

#change the timezone
#import source package, update the source
COPY ./sources.list ./timezone  /
#COPY ./trans /bioapp/
RUN mv /etc/localtime /etc/localtime.old && \
    ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    mv /timezone /etc/ && \
    mv /sources.list /etc/apt/ && \
    apt-get update

#install dependencies
#apt-utils, package managment related utility programs
#git, download source code from github
#build-essential, compile the source code
#zlib, a data compression library, required by bwa
#zlib1g (installed in ubuntu:14.04), runtime
#zlib1g.dev, development
RUN apt-get install -y apt-utils \
    git \
    build-essential \
    zlib1g.dev \
    r-base-core \
    vim

##install bwa
RUN mkdir /bioapp
#WORKDIR /bioapp
#RUN git clone https://github.com/lh3/bwa.git --depth 1
#WORKDIR /bioapp/bwa
#RUN make

##configuration the env
#ENV PATH /bioapp/bwa:$PATH
ENV PATH /bioapp:$PATH

##clean
RUN apt-get clean

##switch the directory
WORKDIR /var/data
