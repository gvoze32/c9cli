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

### Using tmux (BETA)

```
chmod +x c9-maker-tmux.sh
sudo bash c9-maker-tmux.sh
```

To check active user
```
tmux attach
```

If you just want to run separate bash script, you can user this command or run from cloned repository

### Delete User

```
wget https://github.com/gvoze32/C9IDECoreDeploy/raw/master/c9-deluser.sh
chmod +x c9-deluser.sh
bash c9-deluser.sh
```

### Install IonCube

```
wget ioncubesc.sh
chmod +x ioncubesc.sh
bash ioncubesc.sh
```

### Build bonus-instagram packages

```
wget https://raw.githubusercontent.com/gvoze32/C9IDECoreDeploy/master/bonus-instagram.sh
bash bonus-instagram.sh
```

This project is fork of [C9IDE-User-Maker](https://github.com/nicolasjulian/C9IDE-User-Maker) added with own modified packages