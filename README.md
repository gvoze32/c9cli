# C9IDECoreDeploy

Simple bash script to create user and install C9 IDE Workspace then automatically install some required packages.

### Install

Make sure you have root access before doing this installation.

```
$ sudo apt-get update
$ sudo apt-get install dialog
$ git clone https://github.com/gvoze32/C9IDECoreDeploy
$ cd C9IDECoreDeploy
$ chmod +x run.sh
$ sudo bash run.sh
```

If you have any problem in using C9IDECoreDeploy, please head to [FAQ.id](https://github.com/gvoze32/C9IDECoreDeploy/blob/master/FAQ.id.md) before opening a new issue.

Next to-do list is change get resources method using cp instead of downloading files again using wget.

This project is fork of [C9IDE-User-Maker](https://github.com/nicolasjulian/C9IDE-User-Maker) and [C9-Docker-Compose](https://github.com/nicolasjulian/C9-Docker-Compose).