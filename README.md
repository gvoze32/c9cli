# C9IDECoreDeploy

Simple bash script to create user and install C9 IDE Workspace then automatically install some required packages.

### Install

Make sure you have root access before doing this installation.

```
$ git clone https://github.com/gvoze32/C9IDECoreDeploy c9tui
$ cd c9tui
$ chmod +x scripts/install.sh
$ sudo bash scripts/install.sh
```

### Deploy

```
$ sudo bash run.sh
```

If you have any problem in using C9IDECoreDeploy, please open new issue.

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

**This project is fork of [C9IDE-User-Maker](https://github.com/nicolasjulian/C9IDE-User-Maker) and [C9-Docker-Compose](https://github.com/nicolasjulian/C9-Docker-Compose).**
