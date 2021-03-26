  case $2 in
    delete )
    read -p "Input User : " user
    sleep 10
    sudo systemctl stop c9-$user.service
    sleep 10
    sudo killall -u $user
    sleep 10
    sudo deluser --remove-home -f $user
    ;;
    status )
    read -p "Username : " usercore
    sudo systemctl status c9-$usercore.service
    ;;
    restart )
    read -p "Input User : " user
    sudo systemctl daemon-reload
    sudo systemctl enable c9-$user.service
    sudo systemctl restart c9-$user.service
    sleep 10
    sudo systemctl status c9-$user.service
    ;;
    schedule )
    read -p "Input User : " user
    echo " "
    echo "Format Example for Time: "
    echo " "
    echo "10:00 AM 6/22/2015"
    echo "10:00 AM July 25"
    echo "10:00 AM"
    echo "10:00 AM Sun"
    echo "10:00 AM next month"
    echo "10:00 AM tomorrow"
    echo "now + 1 hour"
    echo "now + 30 minutes"
    echo "now + 1 week"
    echo "now + 1 year"
    echo "midnight"
    echo " "
    read -p "Time: " waktu
    at $waktu <<END
    sleep 10
    sudo systemctl stop c9-$user.service
    sleep 10
    sudo killall -u $user
    sleep 10
    sudo deluser --remove-home -f $user
END
    ;;
    scheduled )
    sudo atq
    ;;
    convert )
    read -p "Input User : " user
    echo "Input user password"
    passwd $user
    echo "Warning, C9 will be restart!"
    usermod -aG sudo $user
    sudo systemctl daemon-reload
    sudo systemctl enable c9-$user.service
    sudo systemctl restart c9-$user.service
    sleep 10
    sudo systemctl status c9-$user.service
    ;;
    * )
    echo "Command not found, type c9tui --help for help"
  esac
  ;;