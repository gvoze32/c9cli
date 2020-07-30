#!/bin/bash
read -p "Input User : " user
sudo docker-compose -p $user down
