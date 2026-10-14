# c9cli

c9cli is a command-line interface tool for managing Cloud9 workspaces and Docker containers. It provides a set of commands to create, manage, and monitor development environments efficiently.

## Features

- Quick create C9 workspace in root
- Create and manage SystemD workspaces
- Create and manage Docker containers
- Limit RAM and CPU usage for workspaces
- Manage user accounts and passwords
- Schedule workspace deletions
- Backup workspaces to cloud storage
- Monitor port usage and container status

## Installation

Make sure you have root access before doing this installation.

```bash
sudo curl -fsSL https://jayanode.com/api/mirror/c9cli/build?raw=true | sudo bash
```

## Usage

c9cli must be run as root. The general syntax is:

```bash
c9cli [command] [argument] [argument]
```

To quickly create a C9 workspace in root:

```bash
c9cli quickcreate
```

## Supported Environments

- Ubuntu 18.04, 20.04, 22.04, 24.04 and 26.04 (Debian is untested but accepted by the installer)
- Docker workspace images support Ubuntu 20.04, 22.04, 24.04, and 26.04 Cloud9 image tags
  (`gvoze32/cloud9:focal|jammy|noble|resolute`).

The installer (`scripts/install.sh`) is idempotent. It installs Docker, rclone, `at`, `quota`,
`zip`/`unzip`, Python 2/3 helpers, creates the host users `c9users` and `c9usersmemlimit` with
their `docker-compose.yml`, and merges Docker's `default-address-pools` into `/etc/docker/daemon.json`
without overwriting an existing configuration (Docker is restarted only when that file changed).

## Creating workspaces

Every create command takes its settings as options and only prompts for the ones that are missing,
so it can be scripted (the password prompt does not echo, and passwords are never printed):

```bash
c9cli create dockerlimit -u alice -p 'S3cret!' -o 8001 -l 1024m -c 0.5 -q 10G -i gvoze32/cloud9:jammy
c9cli manage docker restart -u alice
c9cli manage docker stop -u alice -t 2        # -t 1 = c9users, -t 2 = c9usersmemlimit
c9cli manage docker password -u alice -p 'N3wPass!' -o 8001 -t 2 -l 1024m -c 0.5
```

- Usernames may contain letters, digits, `_` and `-`; passwords must not contain a single quote or a newline.
- Invalid or unknown options, a missing option value or stray arguments abort with exit code 2.
- The compose project of a workspace is `c9-<user>` (container name) / `<user>` in lowercase (`-p`).
- Docker creates read the settings from the shell environment *and* write them to `/home/c9users*/.env`
  (mode 600, passwords single-quoted so `$` and `#` survive). Writers serialise on `/home/c9users*/.c9cli.lock`.
- `manage docker reset` recreates a workspace from `.env`, so it refuses to run when `.env` belongs to a
  different user; use `manage docker password` (explicit settings) in that case.
- The storage limit (`-q`) uses ext4 `usrquota` and is skipped with a warning when the quota tools or the
  mount option are missing. `setquota` errors are now shown instead of being swallowed.
- `quickcreate stop|restart|fix|status` only touches the Cloud9 process whose working directory is `/root/c9sdk`;
  it logs to `/var/log/c9cli-quickcreate.log`.

## Backup

c9cli supports backing up workspaces to various cloud storage providers using Rclone.

To set up a backup, use the `c9cli backup` command and follow the prompts.
The generated script (`/home/backup-<name>.sh`) takes a lock so runs never overlap, and re-running
`c9cli backup` for the same remote name replaces its cron entry instead of adding a second one.

Additional folders or files can be included in every archive with the repeatable `-a` option. Paths are relative to each workspace root and may use `{folder}` and `{user}` placeholders:

```bash
c9cli backup -n drive -h 2 -f backups -s 1 -a 'additional/{user}/data'
```

## Updating

To update c9cli to the latest version, run:

```bash
c9cli update
```

The new script is downloaded to a temporary file, syntax-checked and then moved into place atomically.
Interactive sessions check for a new version at most once a day (`/var/lib/c9cli/last_check`); non-interactive
callers never trigger the check.

## Development

```bash
bash -n c9cli.sh build.sh scripts/install.sh
shellcheck -S warning c9cli.sh build.sh scripts/install.sh
bash c9cli.sh help            # help/version need no root
```

`c9cli.sh` only runs `main` when executed, so its functions can be sourced in tests.

## License

This project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0) License. See the LICENSE file for details.

## Information

Using Docker image from [cloud9image](https://github.com/gvoze32/cloud9image)

If you have any problem in using c9cli, please open a new issue.
