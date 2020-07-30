#!/bin/bash
sudo apt update -y
sudo apt upgrade -y
sudo apt update -y
curl -sL https://deb.nodesource.com/setup_12.x | sudo bash -
sudo apt install -y curl at git build-essential nodejs php php-exif php-gd php-mbstring php-curl php-mysqli php-json php-dom php-fpm python-pip python3-pip python python2.7 python-pyfiglet build-essential zip unzip unp unrar unrar-free unar p7zip dos2unix
pip install requests selenium colorama bs4
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.nvm/nvm.sh
systemctl start atd
sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common docker docker.io docker-compose
sudo adduser c9users
sudo wget https://raw.githubusercontent.com/gvoze32/C9IDECoreDeploy/master/misc/dockeryml/docker-compose.yml -O /home/c9users/docker-compose.yml
sudo adduser c9usersmemlimit
sudo wget https://raw.githubusercontent.com/gvoze32/C9IDECoreDeploy/master/misc/dockeryml-memlimit/docker-compose.yml -O /home/c9usersmemlimit/docker-compose.yml
sudo cat > /home/c9users/.env << EOF
blank
EOF
sudo cat > /home/c9usersmemlimit/.env << EOF
blank
EOF