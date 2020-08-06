#!/bin/bash

HEIGHT=15
WIDTH=90
CHOICE_HEIGHT=13
BACKTITLE="Manage Systemctl Workspaces."
TITLE="C9IDECoreDeploy"
MENU="Choose one of the following options:"

OPTIONS=(1 "Delete Workspace"
         2 "See Workspace Status"
		 3 "See Used Port List"
		 4 "Restart Workspace"
		 5 "Schedule Workspace Service Deletion"
		 6 "See Scheduled Workspace Deletion"
		 7 "< Back")

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
			sudo bash scripts/c9-deluser.sh
            ;;
        2)
			sudo bash scripts/c9-status.sh
            ;;
        3)
			sudo lsof -i -P -n | grep LISTEN
            ;;
		4)
			sudo bash scripts/c9-restart.sh
			;;
		5)
			sudo bash scripts/schedule.sh
			;;
		6)
			sudo atq
			;;
		7)
			sudo bash menu/manage.sh
            ;;
esac
