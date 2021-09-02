#!/bin/bash

HEIGHT=15
WIDTH=90
CHOICE_HEIGHT=13
BACKTITLE="Manage Docker Workspaces."
TITLE="c9tui"
MENU="Choose one of the following options:"

OPTIONS=(1 "Delete Docker Container"
		 2 "See Docker Container Lists"
		 3 "See Docker Container Status"
		 4 "Schedule Docker Container Deletion"
		 5 "See Scheduled Docker Containers Deletion"
		 6 "Restart All Running Containers"
		 7 "Stop, Start or Restart Running Containers"
		 8 "< Back")

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
			sudo bash scripts/c9-deluser-docker.sh
            ;;
        2)
            docker ps
            ;;
        3)
            docker stats
            ;;
        4)
			sudo bash scripts/scheduledocker.sh
            ;;
        5)
            sudo atq
            ;;
	    6)
            docker restart $(docker ps -q)
            ;;
	    7)
            sudo bash scripts/restartdocker.sh
            ;;
	    8)
			sudo bash menu/manage.sh
            ;;
esac
