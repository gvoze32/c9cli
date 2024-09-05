# c9cli

Create and manage secure Cloud9 IDE private users using SystemD and Docker services.

## Requirements

- Ubuntu 18.04, 20.04 or 22.04

## Usage

Make sure you have root access before doing this installation.

Get Dependencies

```
sudo wget https://raw.githubusercontent.com/gvoze32/c9cli/master/scripts/install.sh && sudo chmod +x install.sh && sudo ./install.sh
```

Install

```
sudo wget https://raw.githubusercontent.com/gvoze32/c9cli/master/c9cli.sh -O /usr/local/bin/c9cli && sudo chmod +x /usr/local/bin/c9cli
```

## Run

```
c9cli help
```

Using Docker image from [gvoze32/cloud9image](https://github.com/gvoze32/cloud9image) / [dockerhub](https://hub.docker.com/repository/docker/gvoze32/cloud9)

If you have any problem in using c9cli, please open new issue.
