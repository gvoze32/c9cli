#!/bin/bash
wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar -xvzf ioncube_loaders_lin_x86-64.tar.gz
cd ioncube
echo List of supported php versions:
ls
echo .
echo .
echo .
ls /usr/lib/php/
echo .
echo .
echo .
echo Write the PHP extension folder name below, example 20170718
read -p "Folder Name : " folde
echo .
echo .
echo .
php -v
version="$(command php --version 2>'/dev/null' \
    | command head -n 1 \
    | command cut --characters=5-7)"
cp ioncube_loader_lin_${version}.so /usr/lib/php/${folde}
echo .
echo .
echo .
php -i | grep additional
echo .
echo .
echo .
cat > /etc/php/${version}/cli/conf.d/00-ioncube-loader.ini << EOF
zend_extension=ioncube_loader_lin_${version}.so
EOF
php -v
