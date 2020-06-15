#!/bin/bash
sudo apt update -y
sudo apt upgrade -y
sudo apt update -y
sudo apt-get install -y curl git build-essential nodejs npm php php-exif php-gd php-mbstring php-curl php-mysqli php-json php-dom php-fpm python-pip python3-pip python python2.7 python-pyfiglet build-essential zip unzip unp unrar unrar-free unar p7zip apt-transport-https ca-certificates curl gnupg-agent software-properties-common docker docker.io docker-compose
pip install requests selenium colorama bs4
sudo adduser c9users
cd /home/c9users
git clone https://github.com/nicolasjulian/C9-Docker-Compose.git