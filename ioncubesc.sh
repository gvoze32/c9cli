echo Pastikan PHP kamu adalah versi 7.2 dan menggunakan CLI, jika bukan silahkan keluar
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

read -r -p "Jika php kamu menggunakan cli, silahkan ketik y, atau ketik n jika php kamu menggunakan fpm" response
case "$response" in
    [yY][eE][sS]|[yY]) 
sudo bash -c 'echo 'zend_extension=ioncube_loader_lin_7.2.so' > /etc/php/7.2/cli/conf.d/00-ioncube-loader.ini'
service php7.2-fpm restart
php -v
        ;;
    *)
echo 'zend_extension=ioncube_loader_lin_7.2.so' > /etc/php/7.2/fpm/conf.d/00-ioncube-loader.ini
service php7.2-fpm restart
php -v
        ;;
esac