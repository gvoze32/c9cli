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
                                                     
==================================================
"

sudo curl -fsSL https://hostingjaya.ninja/api/mirror/c9cli/install?raw=true | sudo bash

sudo curl -fsSL https://hostingjaya.ninja/api/mirror/c9cli/c9cli?raw=true -o /usr/local/bin/c9cli && sudo chmod +x /usr/local/bin/c9cli

if [ $? -eq 0 ]; then
    echo "c9cli installation successful!"
    sudo c9cli version
    echo "Type 'sudo c9cli help' to see the available commands."
else
    echo -e "\e[31mc9cli installation failed.\e[0m"
fi
