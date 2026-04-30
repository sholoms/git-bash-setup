# Git Bash Setup

This repository provides a script to enhance your Git Bash experience with a rich set of aliases and functions, designed for efficiency, especially in environments where `zsh` is not an option.

## Features

- **Quick Setup**: A single script to install all customizations.
- **Git Aliases**: Shortcuts for many common Git commands.
- **Branching Helpers**: Functions to streamline branch creation and management.
- **History Search**: A simple function to search your command history.
- **Help Function**: An integrated `help_functions` command to explain all custom aliases and functions.

## Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/sholoms/git-bash-setup.git
    ```

2.  **Run the setup script:**
    ```bash
    cd git-bash-setup
    ./setup_bash_customizations.sh
    ```
    The script will prompt you for your Git username to personalize some of the functions.

3.  **Reload your shell:**
    ```bash
    source ~/.bashrc
    ```

## Aliases

The following aliases will be available after installation:

| Alias | Command | Description |
|---|---|---|
| `gl` | `git pull` | Pull changes. |
| `gc` | `git commit` | Commit changes. |
| `gp` | `git push` | Push changes. |
| `gst` | `git status` | Check status. |
| `gd` | `git diff` | View diffs. |
| `gf` | `git fetch` | Fetch changes. |
| `gb` | `git branch` | Manage branches. |
| `repos` | `cd $HOME/source/repos` | Navigate to repos directory. |
| `restart` | `source ~/.bashrc` | Reload bash configuration. |
| `gpsup` | `git push --set-upstream origin $(git branch --show-current)` | Push and set upstream. |
| `gbd` | `git branch --delete` | Delete a branch. |
| `1` | `cd -` | Go to previous directory. |
| `..` | `cd ..` | Go up one directory. |
| `...` | `cd ../..` | Go up two directories. |
| `....` | `cd ../../..` | Go up three directories. |
| `ll` | `ls -lh` | Long list format. |
| `lsa` | `ls -a` | List all files. |
| `lla` | `ls -lha` | Long list format including hidden files. |
| `grs` | `git restore` | Restore files. |
| `dev` | `git checkout _Dev` | Checkout `_Dev` branch. |
| `data` | `git checkout _Data` | Checkout `_Data` branch. |
| `gco` | `git checkout` | Checkout branch. |
| `addalias`| `vim ~/.bashrc` | Edit bashrc file. |
| `ga` | `git add` | Add files to staging. |
| `sweep` | `git branch --merged \| grep -v "\*\|Master\|Main\|Dev" \| xargs -n 1 git branch -d` | Delete merged branches. |
| `gt` | `git stash` | Stash changes. |
| `gtl` | `git stash list` | List stashes. |
| `gtd` | `git stash drop` | Drop a stash. |
| `gtp` | `git stash pop` | Pop a stash. |
| `gts` | `git stash show -p` | Show stash diff. |
| `glo` | `git log --oneline --decorate` | Oneline log. |
| `glog` | `git log --oneline --decorate --graph` | Oneline log with graph. |
| `gloga` | `git log --oneline --decorate --graph --all` | Oneline log with graph for all branches. |
| `wip` | `git add . && git commit -m "WIP"` | Commit all changes with "WIP" message. |
| `unstage` | `git restore --staged` | Unstage files. |

## Functions

### `gcs <branch-pattern>`
Quickly checks out a branch that matches a given pattern. If only one branch matches, it will switch to it automatically.

### `gbdel <branch-pattern>`
Deletes local branches that match a pattern, with safety checks for unmerged work.

### `gcb <b|e|h|other> <branch-name>`
Creates a new branch with a conventional name based on your username.
- `b`: for bugs (`Users/<username>/bugs/<branch-name>`)
- `e`: for epics (`Users/<username>/epics/<branch-name>`)
- `h`: for help
- `other`: for any other branch name

### `search <pattern>`
Searches your command history for a given pattern.

### `help_functions [function-or-alias]`
Displays help information for all custom functions and aliases, or for a specific one.
