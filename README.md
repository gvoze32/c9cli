# c9tui

Simple Cloud9 IDE bash script to create and manage users.

# Install 
Please choose one of the version.

## TUI

### Install

Make sure you have root access before doing this installation.

```
$ git clone https://github.com/gvoze32/c9tui
$ cd c9tui
$ chmod +x scripts/install.sh
$ sudo bash scripts/install.sh
```

### Run

```
$ sudo bash run.sh
```

## CLI

### Install

Make sure you have root access before doing this installation.

```
$ sudo wget https://raw.githubusercontent.com/gvoze32/c9tui/master/c9tui.sh -O /usr/local/bin/c9tui
$ sudo chmod +x /usr/local/bin/c9tui
$ c9tui --help
```

If you have any problem in using c9tui, please open new issue.

# Explanation

There is 3 variables inside the .env file:
```
PORT=
PASSWORD_PELANGGAN=
NAMA_PELANGGAN=
```
PORT= is used to specify the port where the container will be exposed.

NAMA_PELANGGAN= is used to set username login, and directory name which where to mount to docker container.

PASSWORD_PELANGGAN= is used to set password for authenticate.

Optional variables

There is 2 optional variables inside the .env file:
```
CPUS=
MEMORY=
```
CPUS= is used to specify how much limit CPU core will be used. If limit reached, container will be restart, and terminate all session.

MEMORY= is used to specify how much limit ram will be used, limit ram is maximum load. If limit reached, container will be restart, and terminate all session.

**This project is fork of [C9IDE-User-Maker](https://github.com/nicolasjulian/C9IDE-User-Maker) and [C9-Docker-Compose](https://github.com/nicolasjulian/C9-Docker-Compose) with much more improvement and function.**