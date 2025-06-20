#!/bin/bash

echo "
=================================================
             ____ ___   ____ _     ___               
            / ___/ _ \ / ___| |   |_ _|              
           | |  | (_) | |   | |    | |               
           | |___\__, | |___| |___ | |               
  ___ _   _ \____|_/_/ \____|_____|___|  _____ ____  
 |_ _| \ | / ___|_   _|/ \  | |   | |   | ____|  _ \ 
  | ||  \| \___ \ | | / _ \ | |   | |   |  _| | |_) |
  | || |\  |___) || |/ ___ \| |___| |___| |___|  _ < 
 |___|_| \_|____/ |_/_/   \_\_____|_____|_____|_| \_\
                                                     
================================================="

echo ""
while true; do
    echo -n "Do you want to continue? (y/N): "
    read -r REPLY
    case $REPLY in
        [Yy]|[Yy][Ee][Ss])
            echo "Proceeding with installation..."
            break
            ;;
        [Nn]|[Nn][Oo]|"")
            echo "Installation cancelled."
            exit 0
            ;;
        *)
            echo "Please answer yes (y) or no (n)."
            ;;
    esac
done

echo ""
echo "Starting c9cli installation..."
echo ""

echo "Downloading installer script..."
if ! curl -fsSL https://jayanode.com/api/mirror/c9cli/install?raw=true | sudo bash; then
    echo -e "\e[31mFailed to download or execute installer script.\e[0m"
    exit 1
fi

echo "Downloading c9cli binary..."
if ! sudo curl -fsSL https://jayanode.com/api/mirror/c9cli/c9cli?raw=true -o /usr/local/bin/c9cli; then
    echo -e "\e[31mFailed to download c9cli binary.\e[0m"
    exit 1
fi

if ! sudo chmod +x /usr/local/bin/c9cli; then
    echo -e "\e[31mFailed to make c9cli executable.\e[0m"
    exit 1
fi

if command -v c9cli >/dev/null 2>&1; then
    echo -e "\e[32mc9cli installation successful!\e[0m"
    echo ""
    echo "Version information:"
    sudo c9cli version
    echo ""
    echo "Type 'sudo c9cli help' to see the available commands."
else
    echo -e "\e[31mc9cli installation failed - command not found.\e[0m"
    exit 1
fi
