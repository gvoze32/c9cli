#!/bin/bash

HEIGHT=15
WIDTH=40
CHOICE_HEIGHT=4
BACKTITLE="Simple bash script to create user and install C9 IDE Workspace then automatically install some required packages."
TITLE="C9IDECoreDeploy"
MENU="Choose one of the following options:"

OPTIONS=(1 "chmod All Scripts (required to do this once at first installation)"
		 2 "Deploy User Workspace"
         3 "Delete User Workspace"
         4 "See User Workspace Status"
		 5 "Install IonCube for PHP 7.2 (do this only once)"
		 6 "See Used Port List"
		 7 "Install Docker Packages (do this only once)"
		 8 "Deploy Docker User Workspace"
		 9 "Delete Docker User Workspace"
		 10 "See Docker User Workspace Status"
		 11 "Restart User Workspace")

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
            chmod +x scripts/c9-maker.sh
            chmod +x scripts/ioncubesc.sh
            chmod +x scripts/c9-deluser.sh
			chmod +x scripts/c9-maker-docker-install.sh
			chmod +x scripts/c9-maker-docker.sh
			chmod +x scripts/c9-deluser-docker.sh
			chmod +x scripts/c9-status.sh
			chmod +x script/c9-restart.sh
            ;;
        2)
            sudo bash scripts/c9-maker.sh
            ;;
        3)
			sudo bash scripts/c9-deluser.sh
            ;;
        4)
			sudo bash scripts/c9-status.sh
            ;;
        5)
            sudo bash scripts/ioncubesc.sh
            ;;
        6)
            sudo lsof -i -P -n | grep LISTEN
            ;;
        7)
            sudo bash scripts/c9-maker-docker-install.sh
            ;;
        8)
            sudo bash scripts/c9-maker-docker.sh
            ;;
        9)
            sudo bash scripts/c9-deluser-docker.sh
            ;;
        10)
            docker ps -a
            ;;
		11)
			sudo bash script/c9-restart.sh
			;;
esac
