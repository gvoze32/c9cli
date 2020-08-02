#!/bin/bash
curl -O https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar -xvzf ioncube_loaders_lin_x86-64.tar.gz
rm ioncube_loaders_lin_x86-64.tar.gz
cd ioncube
php_ext_dir="$(command php -i | grep extension_dir 2>'/dev/null' \
    | command head -n 1 \
    | command cut --characters=31-38)"
php_version="$(command php --version 2>'/dev/null' \
    | command head -n 1 \
    | command cut --characters=5-7)"
cp ioncube_loader_lin_${php_version}.so /usr/lib/php/${php_ext_dir}
cd ..
rm -rf ioncube
cat > /etc/php/${php_version}/cli/conf.d/00-ioncube-loader.ini << EOF
zend_extension=ioncube_loader_lin_${php_version}.so
EOF
php -v
