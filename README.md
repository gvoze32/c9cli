# c9cli

Create and manage secure Cloud9 IDE private users using Docker or SystemD services.

## Requirements

- Minimum Ubuntu 18.04 or latest LTS's
- Dependency Packages (Included)

## Install

Make sure you have root access before doing this installation.

```
sudo wget https://raw.githubusercontent.com/gvoze32/c9cli/master/c9cli.sh -O /usr/local/bin/c9cli && sudo wget https://raw.githubusercontent.com/gvoze32/c9cli/master/scripts/install.sh && sudo chmod +x /usr/local/bin/c9cli && sudo chmod +x install.sh && sudo ./install.sh
```

## Run

```
c9cli help
```

🔴 Docker service is under maintenance, please use SystemD for creating new users.

## To do

- [x] Change password feature
- [ ] Add custom Docker image
  - [x] 1. Debian Bullseye or latest
  - [ ] 2. Alpine 3.12 or latest
  - [ ] 3. Ubuntu 18.04 or latest
- [x] Delete workspace dir when user is deleted

If you have any problem in using c9cli, please open new issue.
