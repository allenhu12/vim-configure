FROM ubuntu:14.04
#FROM ubuntu:20.04
ARG version
LABEL maintainer Daniel Hsu "daniel.hsu@ruckuswireless.com"

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

#install jdk8
RUN apt-get update \
  && apt-get install -y python-software-properties 
RUN apt-get update \
  && apt-get install -y software-properties-common
RUN add-apt-repository ppa:openjdk-r/ppa
RUN apt-get update \
  && apt-get install -y openjdk-8-jdk \
  && update-alternatives --config java 

#install repo
RUN curl https://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo
RUN chmod a+x /usr/local/bin/repo

##############################
# install python
##############################
ENV PYTHON_VERSION 3.6.1

RUN set -ex \
  && curl -LksS http://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz | tar zxf - -C /usr/src/ \
  && cd /usr/src/Python-${PYTHON_VERSION} \
  && ./configure --with-ssl \
  && make \
  && make install \
  && rm -rf /usr/src/Python-${PYTHON_VERSION} 

# remove several traces of debian python
# RUN apt-get purge -y python.*

# # http://bugs.python.org/issue19846
# # > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
# ENV LANG C.UTF-8

# # gpg: key F73C700D: public key "Larry Hastings <larry@hastings.org>" imported
# ENV GPG_KEY 97FC712E4C024BBEA48A61ED3A5CA953F73C700D

# ENV PYTHON_VERSION 3.5.1

# # if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
# ENV PYTHON_PIP_VERSION 8.1.2

# RUN set -ex \
#         && curl -fSL "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" -o python.tar.xz \
#         && curl -fSL "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" -o python.tar.xz.asc \
#         && export GNUPGHOME="$(mktemp -d)" \
#         && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
#         && gpg --batch --verify python.tar.xz.asc python.tar.xz \
#         && rm -r "$GNUPGHOME" python.tar.xz.asc \
#         && mkdir -p /usr/src/python \
#         && tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
#         && rm python.tar.xz \
#         \
#         && cd /usr/src/python \
#         && ./configure --enable-shared --enable-unicode=ucs4 \
#         && make -j$(nproc) \
#         && make install \
#         && ldconfig \
#         && pip3 install --no-cache-dir --upgrade --ignore-installed pip==$PYTHON_PIP_VERSION \
#         && find /usr/local -depth \
#                 \( \
#                     \( -type d -a -name test -o -name tests \) \
#                     -o \
#                     \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
#                 \) -exec rm -rf '{}' + \
#         && rm -rf /usr/src/python ~/.cache

# # make some useful symlinks that are expected to exist
# RUN cd /usr/local/bin \
#         && ln -s easy_install-3.5 easy_install \
#         && ln -s idle3 idle \
#         && ln -s pydoc3 pydoc \
#         && ln -s python3 python \
#         && ln -s python3-config python-config
# RUN apt install -y software-properties-common



RUN curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.4/gosu-$(dpkg --print-architecture)"
RUN chmod a+x /usr/local/bin/gosu

#RUN apt-get install -y g++ libx11-dev libxkbfile-dev libsecret-1-dev python3 npm

## upgrade git version
RUN add-apt-repository ppa:git-core/ppa -y \
	&&  apt-get update \
	&&  apt-get install git -y


ENV DOCKER_USER hubo

COPY docker-entry.sh /etc/docker-entry.sh
ENTRYPOINT ["/etc/docker-entry.sh"]
#RUN echo "git        ALL=(ALL)       NOPASSWD: ALL" >>/etc/sudoers 

