#!/bin/bash
sudo apt update -y
sudo apt upgrade -y
sudo apt update -y
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.36.0/install.sh | bash
source ~/.profile
source ~/.nvm/nvm.sh
nvm install node
sudo apt install -y curl at git build-essential php php-exif php-gd php-mbstring php-curl php-mysqli php-json php-dom php-fpm python-pip python3-pip python python2.7 python-pyfiglet build-essential zip unzip unp unrar unrar-free unar p7zip dos2unix
pip install requests selenium colorama bs4 wget
systemctl start atd
sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common docker docker.io docker-compose
sudo adduser c9users
sudo wget https://raw.githubusercontent.com/gvoze32/C9IDECoreDeploy/master/misc/dockeryml/docker-compose.yml -O /home/c9users/docker-compose.yml
sudo adduser c9usersmemlimit
sudo wget https://raw.githubusercontent.com/gvoze32/C9IDECoreDeploy/master/misc/dockeryml-memlimit/docker-compose.yml -O /home/c9usersmemlimit/docker-compose.yml
echo "blank" >> /home/c9users/.env
echo "blank" >> /home/c9usersmemlimit/.env
