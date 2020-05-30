read -p "Input User : " user
sudo killall -u $user && sudo deluser --remove-home -f $user