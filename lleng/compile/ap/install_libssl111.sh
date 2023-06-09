#!/bin/bash
echo "install libssl.so.1.1 ..."
wget --no-check-certificate https://www.openssl.org/source/old/1.1.1/openssl-1.1.1.tar.gz
tar -zxvf openssl-1.1.1.tar.gz
cd openssl-1.1.1
mkdir /usr/local/openssl
./config --prefix=/usr/local/openssl
./config -t
make & make install
mv /usr/bin/openssl /usr/bin/openssl.bak
mv /usr/include/openssl /usr/include/openssl.bak
ln -s /usr/local/openssl/bin/openssl /usr/bin/openssl
ln -s /usr/local/openssl/include/openssl /usr/include/openssl
echo "/usr/local/openssl/lib" >> /etc/ld.so.conf
ln -s /usr/local/openssl/lib/libssl.so.1.1 /usr/lib64/libssl.so.1.1
ln -s /usr/local/openssl/lib/libcrypto.so.1.1 /usr/lib64/libcrypto.so.1.1
openssl version
