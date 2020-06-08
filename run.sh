#!/bin/bash

HEIGHT=15
WIDTH=40
CHOICE_HEIGHT=4
BACKTITLE="Simple bash script to create user and install C9 IDE Workspace then automatically install some required packages."
TITLE="C9IDECoreDeploy"
MENU="Choose one of the following options:"

OPTIONS=(1 "Deploy User Workspace"
         2 "Delete User Workspace"
         3 "See User Workspace Status"
	 4 "Install IonCube for PHP 7.2"
	 5 "See Used Port List"

CHOICE=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear
case $CHOICE in
        1)
            #Run as sudo or root user
			read -p "Input User : " user
			read -p "Input Password : " password
			read -p "Input Port (Recomend Range : 1000-5000) : " port

			sudo apt-get update && apt-get upgrade
			curl -sL https://deb.nodesource.com/setup_10.x | sudo bash -
			sudo apt-get install -y curl git build-essential nodejs npm php php-exif php-gd php-mbstring php-curl php-mysqli php-json php-dom php-fpm python-pip python3-pip python python2.7 python-pyfiglet build-essential zip unzip unp unrar unrar-free unar p7zip
			pip install requests selenium colorama bs4

			#Create User
			sudo adduser --disabled-password --gecos "" $user

			#echo "$password" | passwd --stdin $user
			sudo echo -e "$password\n$password" | passwd $user
			mkdir -p /home/$user/my-projects
			cd /home/$user/my-projects
			mkdir bonus-instagram
			cd bonus-instagram
			mkdir hypervote-nulled
			cd hypervote-nulled
			wget https://0x0.st/i-ND.zip
			unzip i-ND.zip
			cd ..
			mkdir hypervote-original
			cd hypervote-original
			wget https://0x0.st/i9wX.zip
			unzip i9wX.zip
			cd ..
			wget https://0x0.st/i-5g.zip
			unzip i-5g.zip
			cd auto_view_story
			npm install
			cd ..
			git clone https://github.com/officialputuid/toolsig
			cd toolsig
			unzip lib.zip
			cd ..
			git clone https://github.com/ikiganteng/toolsigeh
			git clone https://github.com/auliaahmad165/igfeedliker
			git clone https://github.com/areltiyan/igfirstcomment
			git clone https://github.com/sandrocods/instagram-views
			git clone https://github.com/nthanfp/storyloop
			git clone https://github.com/corrykalam/InstagramAPI
			git clone https://github.com/ppabcd/Instagram-Story-Downloader
			cd

			#Get script to user directory
			git clone https://github.com/c9/core.git /home/$user/c9sdk
			sudo chown $user.$user /home/$user -R
			sudo -u $user -H sh -c "cd /home/$user/c9sdk; scripts/install-sdk.sh"
			sudo chown $user.$user /home/$user/ -R
			sudo chmod 700 /home/$user/ -R
			sudo cat > /lib/systemd/system/c9-$user.service << EOF

# Run:
# - systemctl enable c9
# - systemctl {start,stop,restart} c9
#
[Unit]
Description=c9
After=syslog.target network.target

[Service]
Type=simple
ExecStart=/usr/bin/node /home/${user}/c9sdk/server.js -a $user:$password --listen 0.0.0.0 -w /home/$user/my-projects
Environment=NODE_ENV=production PORT=$port
User=$user
Group=$user
UMask=0002
Restart=on-failure

StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=c9

[Install]
WantedBy=multi-user.target
#End
EOF

			sudo systemctl daemon-reload
			sudo systemctl enable c9-$user.service
			sudo systemctl restart c9-$user.service
			sleep 10
			sudo systemctl status c9-$user.service
            ;;
        2)
            read -p "Input User : " ngecrot
			systemctl stop c9-$ngecrot.service
			sudo killall -u $ngecrot && sudo deluser --remove-home -f $ngecrot
            ;;
        3)
			read -p "Username : " crot
            sudo systemctl status c9-$crot.service
            ;;
        4)
            echo Pastikan PHP kamu adalah versi 7.2, jika bukan, silahkan keluar
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

			echo .
			echo Silahkan baca tulisan diatas, apabila ada kata cli, maka php kamu menggunakan cli.
			echo Apabila ada kata fpm, maka php kamu menggunakan fpm.
			echo .
			read -r -p "Jika php kamu menggunakan cli, silahkan ketik Y, atau ketik N jika php kamu menggunakan fpm" response
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
            ;;
        5)
            sudo lsof -i -P -n | grep LISTEN
            ;;
esac
