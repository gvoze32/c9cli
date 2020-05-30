# C9IDECoreDeploy

Bash scripts to automatically create user IDE workspace and add some required packages.

### Install

Make sure you have root access to doing this installation.

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

### Using tmux

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

If you still confuse, open this [cheatsheet](https://tmuxcheatsheet.com/)

**If you just want to run separate bash script, you can user this command or run from cloned repository**

### Delete User

```
chmod +x c9-deluser.sh
bash c9-deluser.sh
```

### Install IonCube

```
wget ioncubesc.sh
chmod +x ioncubesc.sh
bash ioncubesc.sh
```

### Clone bonus-instagram packages

```
bash bonus-instagram.sh
```

This project is fork of [C9IDE-User-Maker](https://github.com/nicolasjulian/C9IDE-User-Maker) added with own modified packages