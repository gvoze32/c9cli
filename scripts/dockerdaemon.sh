#!/bin/bash
sudo wget https://raw.githubusercontent.com/gvoze32/c9tui/master/misc/docker-daemon/daemon.json -O /etc/docker/daemon.json
service docker restart
docker network inspect bridge | grep Subnet