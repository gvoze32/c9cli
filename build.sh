#!/bin/bash

sudo curl -fsSL https://hostingjaya.ninja/api/c9cli/install | sudo bash

sudo curl -fsSL https://hostingjaya.ninja/api/c9cli/c9cli -o /usr/local/bin/c9cli && sudo chmod +x /usr/local/bin/c9cli

if [ $? -eq 0 ]; then
    echo "c9cli installation successful!"
    sudo c9cli version
    echo "Type 'sudo c9cli help' to see the available commands."
else
    echo -e "\e[31mc9cli installation failed.\e[0m"
fi
