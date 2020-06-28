 #!/bin/bash

HEIGHT=15
WIDTH=40
CHOICE_HEIGHT=4
BACKTITLE="Limit CPU and Memory Usage Per User."
TITLE="C9 Docker CPUMEMLimit"
MENU="Choose one of the following options:"

OPTIONS=(1 "Apply CPU & Memory Limit Settings for Docker)"
		 2 "Restore Default)")

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
        sudo bash cpumemlimit.sh
            ;;
        2)
        sudo bash restore.sh
            ;;
esac
