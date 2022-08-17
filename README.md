# c9tui

Cloud9 IDE bash script to safely create and manage private users using Docker or SystemD service.

# Install 
Please choose one of the version.

## TUI

### Install

Make sure you have root access before doing this installation.

```
$ git clone https://github.com/gvoze32/c9tui
$ wget -qO- https://raw.githubusercontent.com/gvoze32/c9tui/master/scripts/install.sh | sudo bash
```

### Run

```
$ sudo bash run.sh
```

## CLI (Recommended)

### Install

Make sure you have root access before doing this installation.

```
$ sudo wget https://raw.githubusercontent.com/gvoze32/c9tui/master/c9tui.sh -O /usr/local/bin/c9tui
$ sudo chmod +x /usr/local/bin/c9tui
$ wget -qO- https://raw.githubusercontent.com/gvoze32/c9tui/master/scripts/install.sh | sudo bash
```

### Run

```
$ c9tui help
```

If you have any problem in using c9tui, please open new issue.
