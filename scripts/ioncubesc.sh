#!/bin/bash
wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar -xvzf ioncube_loaders_lin_x86-64.tar.gz
rm ioncube_loaders_lin_x86-64.tar.gz
cd ioncube
echo List of supported php versions:
ls
folde="$(command php -i | grep extension_dir 2>'/dev/null' \
    | command head -n 1 \
    | command cut --characters=31-38)"
version="$(command php --version 2>'/dev/null' \
    | command head -n 1 \
    | command cut --characters=5-7)"
cp ioncube_loader_lin_${version}.so /usr/lib/php/${folde}
cd ..
rm -rf ioncube
php -i | grep additional
cat > /etc/php/${version}/cli/conf.d/00-ioncube-loader.ini << EOF
zend_extension=ioncube_loader_lin_${version}.so
EOF
php -v
