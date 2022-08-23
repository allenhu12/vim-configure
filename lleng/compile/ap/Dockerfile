FROM centos:centos7

LABEL maintainer lester leng "lester.leng@ruckuswireless.com"
 
RUN yum -y install gcc gcc-c++ wget tar rsync bzip2 m4 which bison flex gettext patch texinfo zlib-devel ncurses-devel ctags autoconf unzip util-linux java-1.7.0-openjdk java-1.7.0-openjdk-devel ant
 
ENV JAVA_HOME /etc/alternatives/java_sdk/

RUN yum -y install vim
RUN yum -y install openssh-clients
RUN yum -y install file
RUN yum -y install glibc.i686 glibc-common.i686 glibc-devel.i686  glibc-headers.i686
RUN yum -y install glibc-static glibc-static.i686
ADD build-in/mkimage /usr/bin/
RUN yum -y install automake
RUN yum -y install imake
RUN yum -y install makedepend
ADD build-in/p4 /usr/bin/
RUN yum -y install sharutils
RUN yum -y install bc
RUN yum -y install zlib.i686
RUN yum -y install libncurses.so.5
RUN yum -y install dtc
RUN yum -y install  make
RUN yum -y install openssl
RUN yum -y install zip

# install pip and for 11ax driver
RUN yum -y install epel-release
RUN yum -y install python-pip
#RUN pip install --upgrade pip
#RUN pip install openpyxl==2.3.0
RUN yum install -y openssl-devel
RUN yum install -y libtool
RUN yum install -y lzo-devel
RUN yum install -y lz4
RUN yum install -y git
RUN yum install -y net-tools
RUN yum install -y tree
#RUN yum remove -y python-pip 
#RUN yum install -y python-pip
RUN pip install openpyxl==2.3.0
RUN yum install -y moreutils

RUN mkdir -p /tmp/docker && curl -fsSL https://get.docker.com -o /tmp/docker/get-docker.sh \
    && chmod +x /tmp/docker/get-docker.sh && DRY_RUN=1 && bash /tmp/docker/get-docker.sh
