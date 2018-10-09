#!/bin/bash

chkpkg=`dpkg-query -W nginx 2>&1 | grep 'no packages found'` || true
if [ -n "$chkpkg" ]; then
    wget -q http://nginx.org/keys/nginx_signing.key
    apt-key add nginx_signing.key
    rm nginx_signing.key
    codename=`lsb_release -c |awk '{print $2}'`
    echo "deb http://nginx.org/packages/ubuntu/ $codename nginx" >> /etc/apt/sources.list
    apt-get update
    apt-get install -y nginx
fi
