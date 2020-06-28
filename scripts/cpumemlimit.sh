#!/bin/bash
file=/home/c9users/docker-compose.yml
if [ -e "$file" ]; then
    rm /home/c9users/docker-compose.yml
    sudo cat > /home/c9users/docker-compose.yml << EOF
version: '2.2'
services:
  cloud9:
    image: sapk/cloud9:latest
    volumes:
      - /home/c9users/${NAMA_PELANGGAN}:/workspace
    restart: always
    ports:
      - "${PORT}:${PORT}"
    command:
      - --auth=${NAMA_PELANGGAN}:${PASSWORD_PELANGGAN}
      - --port=${PORT}
# Optinal uncomment if you need to use it.
    mem_limit: ${MEMORY}
    cpus: ${CPUS}
EOF
else 
        sudo cat > /home/c9users/docker-compose.yml << EOF
version: '2.2'
services:
  cloud9:
    image: sapk/cloud9:latest
    volumes:
      - /home/c9users/${NAMA_PELANGGAN}:/workspace
    restart: always
    ports:
      - "${PORT}:${PORT}"
    command:
      - --auth=${NAMA_PELANGGAN}:${PASSWORD_PELANGGAN}
      - --port=${PORT}
# Optinal uncomment if you need to use it.
    mem_limit: ${MEMORY}
    cpus: ${CPUS}
EOF
fi 
