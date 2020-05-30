#!/bin/bash
#Run as sudo or root user
read -p "Input User : " user
read -p "Input Password : " password
read -p "Input Port (Recomend Range : 1000-5000) : " port

sudo apt-get update && apt-get -y install curl git
sudo apt-get install -y build-essential nodejs npm php php-exif php-gd php-mbstring php-curl php-mysqli php-json php-dom php-fpm python-pip python3-pip python python2.7 python-pyfiglet build-essential zip unzip unp unrar unrar-free unar p7zip
sudo pip install requests selenium colorama bs4

#Create User
sudo adduser --disabled-password --gecos "" $user

#echo "$password" | passwd --stdin $user
sudo echo -e "$password\n$password" | passwd $user
mkdir -p /home/$user/my-projects
cd /home/$user/my-projects
wget https://raw.githubusercontent.com/gvoze32/C9IDECoreDeploy/master/bonus-instagram.sh
bash bonus-instagram.sh
cd

#Get script to user directory
git clone https://github.com/c9/core.git /home/$user/c9sdk
sudo chown $user.$user /home/$user -R
sudo -u $user -H sh -c "cd /home/$user/c9sdk; scripts/install-sdk.sh"
sudo chown $user.$user /home/$user/ -R
sudo chmod 700 /home/$user/ -R
sudo tmux new -d -s c9
sudo tmux new -d -n $user
sudo tmux send-keys -t c9:$user "node server.js --auth $user:$password --listen 0.0.0.0 --port $port -w /home/$user/my-projects" Enter

# ATTENTION! Script not finished yet, don't run it.