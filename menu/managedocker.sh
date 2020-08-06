#!/bin/bash

HEIGHT=15
WIDTH=90
CHOICE_HEIGHT=13
BACKTITLE="Manage Docker Workspaces."
TITLE="C9IDECoreDeploy"
MENU="Choose one of the following options:"

OPTIONS=(1 "Delete Docker Workspace"
		 2 "See Docker Workspace List"
		 3 "See Docker Workspace Status"
		 4 "Schedule Docker Workspace Deletion"
		 5 "See Scheduled Docker Workspace Deletion")

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
			cd ../scripts && sudo bash scripts/c9-deluser-docker.sh
            ;;
        2)
            docker ps
            ;;
        3)
            docker stats
            ;;
        4)
			cd ../scripts && sudo bash scripts/scheduledocker.sh
            ;;
        5)
            sudo atq
            ;;
esac
