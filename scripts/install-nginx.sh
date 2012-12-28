#!/bin/bash

set -e
set -x

download_version="1.2.6"
download_url="http://nginx.org/download/nginx-${download_version}.tar.gz"

tmp_dir=$(mktemp -d)
cd $tmp_dir
wget $download_url
tar xf nginx-$download_version.tar.gz
cd nginx-$download_version
./configure --prefix=$1
make
make install
rm -rf $tmp_dir
