# Bash Setup Customizations

This repository provides a comprehensive Bash setup script that personalizes and streamlines your command-line experience for development workflows. The setup script automates the installation of useful aliases and functions, with a focus on developer convenience, Git productivity, and safe database management.

## Features

### 1. **Git Aliases and Shortcuts**
Provides numerous helpful, memorable aliases for common Git commands, such as:
- `gl` : `git pull`  
- `gc` : `git commit`  
- `gp` : `git push`  
- `gst` : `git status`
- `gb` : `git branch`
- `gpsup` : `git push --set-upstream origin $(git branch --show-current)`
- Shortcuts for git stash management, branch deletion, and branch switching

### 2. **Navigational Aliases**
Boosts your navigation speed with:
- Directory jump aliases (`1`, `..`, `...`, `....`)
- `repos` : Quickly navigate to your main repositories folder
- `restart` : Reload `.bashrc` to apply changes

### 3. **Handy File Listing Aliases**
Aliases like:
- `ll`: `ls -lh`
- `lsa`: `ls -a`
- `lla`: `ls -lha`

### 4. **Advanced Git Functions**
Includes interactive and pattern-based branch switching and cleaning:
- `gcs`: Quickly checkout a branch by pattern match, with smart matching
- `gbdel`: Safely delete branches by pattern, with clear warnings and confirmation

### 5. **Custom Search & History Tools**
- `search`: Search your command history for patterns

### 6. **Extensible Help System**
- `help_functions`:  
  - Lists available functions and aliases with summaries  
  - `help_functions <name>` gives details for a specific function or alias  
  - `help_functions restoredb` shows a full help message (delegated to `restoredb_help`)

### 7. **Setup Automation**
- Ensures that all aliases and functions are correctly added to your `.bashrc` and `~/.bash_functions`
- Makes sure `.bash_functions` is sourced if not already
- Avoids duplicate entries for aliases and completion helpers

## Getting Started

1. **Place the `setup_bash_customizations.sh` file in your home directory.**
2. Run the setup script:
    ```bash
    bash setup_bash_customizations.sh
    ```
3. Restart your shell, or run:
    ```bash
    source ~/.bashrc
    ```
4. Try out the new commands! For help, just type:
    ```bash
    help_functions
    ```

## Customization

- The setup script prompts for your Git branch username to personalize branches for your workflow.
- You can further edit your `.bashrc` and `~/.bash_functions` for additional tweaks.
---

Feel free to open an issue or PR for improvements or bugs!
