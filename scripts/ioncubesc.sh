#!/bin/bash
wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar -xvzf ioncube_loaders_lin_x86-64.tar.gz
cd ioncube
echo .
echo .
echo .
ls /usr/lib/php/
echo .
echo .
echo .
echo Write the PHP extension folder name below
read -p "Folder Name : " folde
echo .
echo .
echo .
php -v
echo Write the php version below
read -p "Version : " version
sudo cp ioncube_loader_lin_$version.so /usr/lib/php/$folde
echo .
echo .
echo .
php -i | grep additional
        ;;
    *)
        :
        ;;
esac
echo .
echo .
echo .
echo Read text above, if there is cli in it, you have php cli version.
echo If the text contains fpm, then you have php fpm version.
echo .
read -r -p "If you have cli, press Y, or press N if you have fpm : " response
case "$response" in
    [yY][eE][sS]|[yY]) 
sudo bash -c 'echo 'zend_extension=ioncube_loader_lin_$version.so' > /etc/php/$version/cli/conf.d/00-ioncube-loader.ini'
service php$version-fpm restart
php -v
        ;;
    *)
sudo bash -c 'echo 'zend_extension=ioncube_loader_lin_$version.so' > /etc/php/$version/fpm/conf.d/00-ioncube-loader.ini'
service php$version-fpm restart
php -v
        ;;
esac
