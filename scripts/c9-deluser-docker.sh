#!/bin/bash
read -p "Input User : " user
sudo docker-compose --env-file=$user.env -p $user.env down -d
