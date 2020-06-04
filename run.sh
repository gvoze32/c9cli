#!/bin/bash

HEIGHT=15
WIDTH=40
CHOICE_HEIGHT=4
BACKTITLE="Original script by nicolasjulian modified by gvoze32"
TITLE="C9IDECoreDeploy"
MENU="Choose one of the following options:"

OPTIONS=(1 "Deploy User Workspace"
         2 "Delete User Workspace"
         3 "See User Workspace Status"
		 4 "Install IonCube for PHP 7.2"
		 5 "See Used Port List"
		 6 "chmod All Scripts")

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
            sudo bash scripts/c9-maker.sh
            ;;
        2)
            sudo bash scripts/c9-deluser.sh
            ;;
        3)
			read -p "Username : " crot
            sudo systemctl status c9-$crot.service
            ;;
        4)
            sudo bash scripts/ioncubesc.sh
            ;;
        5)
            sudo lsof -i -P -n | grep LISTEN
            ;;
        6)
            chmod +x scripts/c9-maker.sh
            chmod +x scripts/ioncubesc.sh
            chmod +x scripts/c9-deluser.sh
            ;;
esac
