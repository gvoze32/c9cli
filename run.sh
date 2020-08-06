#!/bin/bash

HEIGHT=15
WIDTH=90
CHOICE_HEIGHT=13
BACKTITLE="Simple bash script to create user and install C9 IDE Workspace."
TITLE="C9IDECoreDeploy"
MENU="Choose one of the following options:"

OPTIONS=(1 "Install"
		 2 "Deploy"
		 3 "Manage")

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
			sudo bash menu/install.sh
            ;;
        2)
			sudo bash menu/deploy.sh
            ;;
        3)
            sudo bash menu/manage.sh
            ;;
esac
