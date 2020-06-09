#!/bin/bash
echo Make sure you have PHP 7.2, if not... please exit
read -r -p "Continue? [y/N] " response
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
echo Read text above, if there is cli in it, you have php cli version.
echo If the text contains fpm, then you have php fpm version.
echo .
read -r -p "If you have cli, press Y, or press N if you have fpm" response
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