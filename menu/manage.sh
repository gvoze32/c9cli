#!/bin/bash

HEIGHT=15
WIDTH=90
CHOICE_HEIGHT=13
BACKTITLE="Manage Workspaces."
TITLE="c9tui"
MENU="Choose one of the following options:"

OPTIONS=(1 "Systemctl"
    2 "Docker"
    3 "Backup"
    4 "< Back")

CHOICE=$(
    dialog --clear \
    --backtitle "$BACKTITLE" \
    --title "$TITLE" \
    --menu "$MENU" \
    $HEIGHT $WIDTH $CHOICE_HEIGHT \
    "${OPTIONS[@]}" \
    2>&1 >/dev/tty
)

clear
case $CHOICE in
1)
    sudo bash menu/managesystemctl.sh
    ;;
2)
    sudo bash menu/managedocker.sh
    ;;
3)
    echo "RUN THIS COMMAND ONLY ONCE!"
    echo "Backup choice:"
    echo "1. Backup         : Backup workspace data with rclone in one archive"
    echo "2. Backup Lite    : Backup workspace data with rclone, with each workspace folder zipped"
    read -r -p "Choose: " response
    case "$response" in
    1)
        sudo bash scripts/rclone.sh
        ;;
    *)
        sudo bash scripts/rclonelite.sh
        ;;
    esac
    ;;
4)
    sudo bash run.sh
    ;;
esac
