#!/bin/bash

HEIGHT=15
WIDTH=90
CHOICE_HEIGHT=13
BACKTITLE="Install packages."
TITLE="C9IDECoreDeploy"
MENU="Choose one of the following options:"

OPTIONS=(1 "chmod +x All Scripts"
		 2 "Install Required Packages"
		 3 "Auto Install IonCube PHP Loader"
		 4 "< Back")

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
			chmod +x menu/manage.sh
			chmod +x menu/dockermenu.sh
			chmod +x menu/managesystemctl.sh
			chmod +x menu/managedocker.sh
			chmod +x menu/install.sh
			chmod +x scripts/c9-maker.sh
			chmod +x scripts/ioncubesc.sh
			chmod +x scripts/c9-deluser.sh
			chmod +x scripts/c9-maker-docker.sh
			chmod +x scripts/c9-deluser-docker.sh
			chmod +x scripts/c9-status.sh
			chmod +x scripts/c9-restart.sh
			chmod +x scripts/schedule.sh
			chmod +x scripts/firstinstall.sh
			chmod +x scripts/c9-maker-dockermemlimit.sh
			chmod +x run.sh
            ;;
        2)
			sudo bash scripts/firstinstall.sh
            ;;
        3)
			sudo bash scripts/ioncubesc.sh
            ;;
        4)
			sudo bash run.sh
            ;;
esac
