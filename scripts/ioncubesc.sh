#!/bin/bash
echo Pastikan PHP kamu adalah versi 7.2, jika bukan, silahkan keluar
read -r -p "Yakin ingin melanjutkan? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY]) 
wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar -xvzf ioncube_loaders_lin_x86-64.tar.gz
cd ioncube
sudo cp ioncube_loader_lin_7.2.so /usr/lib/php/20170718
php -i | grep additional
        ;;
    *)
        :
        ;;
esac

echo .
echo Silahkan baca tulisan diatas, apabila ada kata cli, maka php kamu menggunakan cli.
echo Apabila ada kata fpm, maka php kamu menggunakan fpm.
echo .
read -r -p "Jika php kamu menggunakan cli, silahkan ketik Y, atau ketik N jika php kamu menggunakan fpm" response
case "$response" in
    [yY][eE][sS]|[yY]) 
sudo bash -c 'echo 'zend_extension=ioncube_loader_lin_7.2.so' > /etc/php/7.2/cli/conf.d/00-ioncube-loader.ini'
service php7.2-fpm restart
php -v
        ;;
    *)
sudo bash -c 'echo 'zend_extension=ioncube_loader_lin_7.2.so' > /etc/php/7.2/fpm/conf.d/00-ioncube-loader.ini'
service php7.2-fpm restart
php -v
        ;;
esac