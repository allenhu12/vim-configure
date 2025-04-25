FROM ubuntu:18.04
#FROM ubuntu:20.04
ARG version
LABEL maintainer lleng "lleng@ruckuswireless.com"

RUN chown -fR root:root / 2>/dev/null || true \
  && mkdir /tftpboot \
  && chmod a+rwxt /tftpboot \
  && chmod a+rwxt /tmp \
  && chmod a+rwxt /var/tmp 

RUN apt-get update -y

RUN apt-get install -y uuid-dev

# #Toolchain
RUN apt-get install -y gcc-aarch64-linux-gnu
RUN apt-get install -y clang-6.0

# other tool
RUN apt-get install -y curl
RUN apt-get install -y vim tree 

RUN curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.4/gosu-$(dpkg --print-architecture)"
RUN chmod a+x /usr/local/bin/gosu
COPY docker-entry.sh /usr/local/bin/docker-entry.sh
ENTRYPOINT ["/usr/local/bin/docker-entry.sh"]

RUN apt-get install -y patch



RUN apt-get update &&\
    apt-get install -y \
        sudo time git-core subversion build-essential g++ bash make \
        libssl-dev patch libncurses5 libncurses5-dev zlib1g-dev gawk \
        flex gettext wget unzip xz-utils python python-distutils-extra \
        python3 python3-distutils-extra rsync curl libsnmp-dev liblzma-dev \
        libpam0g-dev cpio rsync
# this refer to https://github.com/mwarning/docker-openwrt-builder


RUN apt install -y build-essential checkinstall
RUN apt install -y python golang-go bison flex gettext ant file device-tree-compiler xutils-dev zlib1g-dev gawk gcc zip u-boot-tools texinfo autoconf make time subversion bsdmainutils cpio ctags exuberant-ctags patch m4 bzip2 tar xorriso g++ rpm alien squashfs-tools libtool qemu qemu-system libprotoc-dev libglib2.0-dev libperl-dev libreadline-gplv2-dev libncurses5 libncurses5-dev libncursesw5-dev libssl-dev libsqlite3-dev libgdbm-dev libbz2-dev liblzma-dev libpam0g-dev uuid-dev python3 python3-distutils-extra python3-pip bsdmainutils
RUN apt install -y clang-6.0 libc6-dev libc6 libsnmp-dev git wget rsync curl


# For sudo
RUN apt-get install -y sudo
RUN  chmod u+s /usr/bin/sudo \
  &&  echo "# pass env variables to CLI" >>/etc/sudoers \
  &&  echo "lleng        ALL=(ALL)       NOPASSWD: ALL" >>/etc/sudoers \
  &&  sed -ie 's#requiretty#!requiretty#g' /etc/sudoers \
  &&  echo "Defaults    !requiretty" >> /etc/sudoer
