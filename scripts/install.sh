#!/bin/bash
sudo apt update -y
sudo apt upgrade -y
sudo apt update -y
curl https://rclone.org/install.sh | sudo bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash
source ~/.profile
nvm install node
sudo apt install -y dialog curl at git mc cpulimit npm build-essential php php-exif php-gd php-mbstring php-curl php-mysqli php-json php-dom php-fpm python python2.7 python3-pip zip unzip unp unrar unrar-free unar p7zip dos2unix
curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
sudo python2 get-pip.py
pip3 install requests selenium colorama bs4 wget pyfiglet
pip2 install requests selenium colorama bs4 wget pyfiglet
systemctl start atd
sudo apt install -y pythonpy apt-transport-https ca-certificates curl gnupg-agent software-properties-common docker docker.io docker-compose
sudo adduser --disabled-password --gecos "" c9users
sudo wget https://raw.githubusercontent.com/gvoze32/c9cli/master/scripts/misc/dockeryml/docker-compose.yml -O /home/c9users/docker-compose.yml
sudo adduser --disabled-password --gecos "" c9usersmemlimit
sudo wget https://raw.githubusercontent.com/gvoze32/c9cli/master/scripts/misc/dockeryml-memlimit/docker-compose.yml -O /home/c9usersmemlimit/docker-compose.yml
echo "blank" >> /home/c9users/.env
echo "blank" >> /home/c9usersmemlimit/.env
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
read -r -p "Increase docker network limit to more than 30 containers? [y/N] (Default = n): " response
case "$response" in [yY][eE][sS]|[yY]) 
        sudo wget https://raw.githubusercontent.com/gvoze32/c9cli/master/scripts/misc/docker-daemon/daemon.json -O /etc/docker/daemon.json
        service docker restart
        sudo docker network inspect bridge | grep Subnet
    ;;
    *)
        echo "default docker version set"
    ;;
esac