#!/bin/bash

# Update packages
sudo apt update -y
sudo apt upgrade -y
sudo apt update -y

# Install rclone
curl https://rclone.org/install.sh | sudo bash

# Install nvm-nodejs
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash
source ~/.profile
nvm install node

# Install dependencies
sudo apt install -y dialog curl at git mc cpulimit npm build-essential php php-exif php-gd php-mbstring php-curl php-mysqli php-json php-dom php-fpm python python2.7 python3-pip zip unzip unp unrar unrar-free unar p7zip dos2unix
curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
sudo python2 get-pip.py
pip3 install requests selenium colorama bs4 wget pyfiglet
pip2 install requests selenium colorama bs4 wget pyfiglet
systemctl start atd
sudo apt install -y pythonpy apt-transport-https ca-certificates curl gnupg-agent software-properties-common docker docker.io docker-compose

# Add docker compose
sudo adduser --disabled-password --gecos "" c9users
sudo cat > /home/c9users/docker-compose.yml << EOF
version: '2.2'
services:
  cloud9:
    image: sapk/cloud9:latest
    volumes:
      - /home/c9users/${NAMA_PELANGGAN}:/workspace
    restart: always
    ports:
      - "${PORT}:${PORT}"
    command:
      - --auth=${NAMA_PELANGGAN}:${PASSWORD_PELANGGAN}
      - --port=${PORT}
EOF

# Add docker compose memlimit
sudo adduser --disabled-password --gecos "" c9usersmemlimit
sudo cat > /home/c9usersmemlimit/docker-compose.yml << EOF
version: '2.2'
services:
  cloud9:
    image: sapk/cloud9:latest
    volumes:
      - /home/c9usersmemlimit/${NAMA_PELANGGAN}:/workspace
    restart: always
    ports:
      - "${PORT}:${PORT}"
    command:
      - --auth=${NAMA_PELANGGAN}:${PASSWORD_PELANGGAN}
      - --port=${PORT}
# This rule is optional, uncomment if you need to use it.
    mem_limit: ${MEMORY}
    cpus: ${CPUS}
EOF

# Create blank .env files
> /home/c9users/.env
> /home/c9usersmemlimit/.env

# Custom docker daemon service option
if whiptail --yesno "Increase docker network limit to more than 30 containers? [y/N] (Default = n): " 20 60 ;then
    echo "Setting docker daemon service rule.."
    sudo cat > /etc/docker/daemon.json << EOF
{
    "default-address-pools": [
        {
            "base": "10.10.0.0/16",
            "size": 24
        }
    ]
}
EOF
    service docker restart
    sudo docker network inspect bridge | grep Subnet
    echo "Done."
else
    echo ""
    echo "==============================="
    echo " Default docker version is set "
    echo "==============================="
    echo ""
    echo ""
fi

# Install ioncube
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