#!/bin/bash

HEIGHT=15
WIDTH=90
CHOICE_HEIGHT=13
BACKTITLE="Docker menu."
TITLE="C9IDECoreDeploy"
MENU="Choose one of the following options:"

OPTIONS=(1 "Docker"
		 2 "Docker with Memory Limit")

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
            sudo bash ../scripts/c9-maker-docker.sh
            ;;
		2)
			sudo bash ../scripts/c9-maker-dockermemlimit.sh
			;;
esac
