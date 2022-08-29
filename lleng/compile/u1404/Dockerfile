FROM ubuntu:14.04
#FROM ubuntu:20.04
ARG version
LABEL maintainer lester leng "lester.leng@ruckuswireless.com"

ENV GOLANG_VERSION 1.13.3
ENV GOROOT /usr/local/go

RUN chown -fR root:root / 2>/dev/null || true \
  && mkdir /tftpboot \
  && chmod a+rwxt /tftpboot \
  && chmod a+rwxt /tmp \
  && chmod a+rwxt /var/tmp 
RUN apt-get update -y

# For i386 compatibility
RUN apt-get install -y libc6-i386 lib32stdc++6 lib32ncurses5 lib32bz2-1.0 lib32z1

# Common
RUN apt-get install -y build-essential bison atfs autoconf flex gettext libncurses5-dev ctags sharutils zlib1g-dev gawk texinfo rsync xutils-dev zip unzip libtool bc wget curl dnsutils vim

RUN apt-get install -y liblzma-dev exuberant-ctags m4 gcc-multilib automake autogen xz-utils tftpd-hpa openssh-server language-pack-en-base pkg-config python-pip squashfs-tools bsdmainutils qemu-utils libssl-dev git

# For build MQTT
RUN apt-get install -y python

# For ARM-QCA
RUN apt-get install -y uuid-dev u-boot-tools device-tree-compiler

# Foe AP VAP
# RUN apt-get install -y ruby-dev rpm python-setuptools python-dev
# RUN gem install fpm


# For tensilica (i386 binary)
# We have to install gcc here due to gcc will be removed due to i386 libc
#RUN apt-get install -y zlib1g-dev:i386 gcc

# 11ax dependency
# Please ref https://jira-wiki.ruckuswireless.com/pages/viewpage.action?pageId=36408622
# Download jdcal-1.0.tar.gz, et_xmlfile-1.0.0.tar.gz, openpyxl-2.3.0-b2.tar.gz to your local build-in/pip/
COPY build-in/pip/* /tmp/pip/
RUN pip install /tmp/pip/*.gz

# For sudo
RUN apt-get install -y sudo
RUN  echo "search video54.local" > /etc/resolv.conf \
  &&  echo "nameserver 10.10.10.10" >> /etc/resolv.conf \
  &&  nslookup "espp-repository.video54.local" \
  &&  chmod u+s /usr/bin/sudo \

  &&  echo "# pass env variables to CLI" >>/etc/sudoers \
  &&  echo "vagrant        ALL=(ALL)       NOPASSWD: ALL" >>/etc/sudoers \
  &&  sed -ie 's#requiretty#!requiretty#g' /etc/sudoers \
  &&  echo "Defaults    !requiretty" >> /etc/sudoers  

# For ZD JAVA applet (Optional)
RUN apt-get install -y ant openjdk-6-jdk openjdk-7-jdk

# Set an utf-8 locale (needed by uClibc)
RUN apt-get install -y locales
RUN echo "LC_ALL=\"en_US.UTF-8\"" >> /etc/default/locale
RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8

# golang
RUN curl -LksS https://storage.googleapis.com/golang/go${GOLANG_VERSION}.linux-amd64.tar.gz | tar zxf - -C /usr/local
RUN echo "export PATH=/usr/local/go/bin:$PATH" >> /root/.bashrc
ENV PATH="/usr/local/go/bin:$PATH"
# ACX rtty
RUN apt-get install -y cmake

#additional tools
RUN apt-get install -y lrzsz
RUN apt-get install -y ccache
RUN echo "export PATH=/usr/lib/ccache:$PATH" >> /root/.bashrc
ENV PATH="/usr/local/go/bin:$PATH"
RUN apt-get install -y moreutils

#ADD docker-entry.sh /usr/local/bin/docker-entry.sh
ADD build-in/cmd/p4 /usr/local/bin/p4
RUN ln -sf /bin/sed /usr/bin/sed
RUN ln -sf /bin/mkdir /usr/bin/mkdir

#ENTRYPOINT ["/usr/local/bin/docker-entry.sh"]

#RUN apt-get install -y g++ libx11-dev libxkbfile-dev libsecret-1-dev python3 npm



