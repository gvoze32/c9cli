# C9IDECoreDeploy

Simple bash script to create user and install C9 IDE Workspace then automatically install some required packages.

### Install

Make sure you have root access before doing this installation.

```
git clone https://github.com/gvoze32/C9IDECoreDeploy
cd C9IDECoreDeploy
chmod +x c9-maker.sh
sudo bash c9-maker.sh
```

To check active user

```
sudo systemctl status c9-username.service
```

### Using tmux (BETA)

```
chmod +x c9-maker-tmux.sh
sudo bash c9-maker-tmux.sh
```

To check active sessions

```
tmux list-sessions
```

To attach selected session

```
tmux a -t sessionname
```

If you still confuse, open this [cheatsheet](https://tmuxcheatsheet.com/).

**If you just want to run additional bash scripts, you can use this command**

### Delete User

```
chmod +x c9-deluser.sh
bash c9-deluser.sh
```

### Install IonCube for PHP 7.2

```
chmod +x ioncubesc.sh
bash ioncubesc.sh
```

### Clone bonus-instagram packages

```
bash bonus-instagram.sh
```

This project is fork of [C9IDE-User-Maker](https://github.com/nicolasjulian/C9IDE-User-Maker) added with own modified packages
