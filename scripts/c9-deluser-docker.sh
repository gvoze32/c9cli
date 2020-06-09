#!/bin/bash
read -p "Input User : " user
sudo docker-compose --env-file $user.c9 -p $user.c9 down -d