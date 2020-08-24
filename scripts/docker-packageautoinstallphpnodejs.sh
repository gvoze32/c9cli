#!/bin/bash
apt update
apt upgrade
apt update
apt install apt-transport-https lsb-release ca-certificates
curl -o /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
apt update
apt install php7.2
apt install php7.2-exif php7.2-gd php7.2-mbstring php7.2-curl php7.2-mysqli php7.2-json php7.2-dom php7.2-fpm
curl -O https://raw.githubusercontent.com/gvoze32/C9IDECoreDeploy/master/scripts/ioncubesc.sh
bash ioncubesc.sh
curl -sL https://deb.nodesource.com/setup_12.x | bash -
apt install nodejs
