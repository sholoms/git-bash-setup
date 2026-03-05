#!/bin/bash

# Define which files we work with
BASHRC="$HOME/.bashrc"
FUNCFILE="$HOME/.bash_functions"

# === Create the Restore-DB.sql file used by the restoredb function ===
SQL_DIRECTORY="$HOME/Documents/Useful SQL"
SQL_FILE="$SQL_DIRECTORY/Restore-DB.sql"

mkdir -p "$SQL_DIRECTORY"

cat > "$SQL_FILE" <<'EOF'
USE [master]
ALTER DATABASE [Hamaspik_Dev] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

RESTORE DATABASE [Hamaspik_Dev]
  FROM DISK = N'C:\Temp\$(backup_filename)'
  WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 5;

ALTER DATABASE [Hamaspik_Dev] SET MULTI_USER;
GO
USE [Hamaspik_Dev];
EOF
# === END: create Restore-DB.sql ===

# Prompt for the Git branch username (only once per setup)
read -p "Enter your Git username for branch prefixes: " GIT_BRANCH_USER

# Aliases to add
cat > /tmp/new_aliases <<'EOF'
# BEGIN CUSTOM ALIASES
alias gl='git pull'
alias gc='git commit'
alias gp='git push'
alias gst='git status'
alias gd='git diff'
alias gf='git fetch'
alias gb='git branch'
alias repos='cd $HOME/source/repos'
alias restart='source ~/.bashrc'
alias gpsup='git push --set-upstream origin $(git branch --show-current)'
alias gbd='git branch --delete'
alias 1='cd -'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ll='ls -lh'
alias lsa='ls -a'
alias lla='ls -lha'
alias grs='git restore'
alias dev='git checkout _Dev'
alias data='git checkout _Data'
alias gco='git checkout'
alias addalias='vim ~/.bashrc'
alias ga='git add'
alias gddev='git diff origin/_Dev'
alias gddata='git diff origin/_Data'
alias sweep='git branch --merged | grep -v "\*\|Kings_Master\|_Dev\|_Data" | xargs -n 1 git branch -d'
alias gt='git stash'
alias gtl='git stash list'
alias gtd='git stash drop'
alias gtp='git stash pop'
alias gts='git stash show -p'

# END CUSTOM ALIASES
EOF

# Functions to add/update (all but gcb, which is appended after with username substituted)
cat > /tmp/new_functions <<'EOF'
# BEGIN CUSTOM FUNCTIONS

function gcs() {
    if [[ -z "$1" ]]; then
        echo "Usage: gcs <branch-pattern>"
        return 1
    fi

    # Get matching branches (remove * and whitespace)
    local branches=($(git branch | grep -i "$1" | sed 's/^[* ]*//'))

    if [[ ${#branches[@]} -eq 0 ]]; then
        echo "No branches found matching: $1"
        return 1
    elif [[ ${#branches[@]} -eq 1 ]]; then
        git checkout "${branches[0]}"
    else
        echo "Multiple branches found matching '$1':"
        printf '  %s\n' "${branches[@]}"
        echo ""
        echo "Please be more specific."
        return 1
    fi
}

function gbdel() {
    if [[ -z "$1" ]]; then
        echo "Usage: gbdel <branch-pattern>"
        return 1
    fi

    # Get current branch
    local current_branch=$(git branch --show-current)

    # Get matching branches (remove * and whitespace)
    local branches=($(git branch | grep -i "$1" | sed 's/^[* ]*//'))

    if [[ ${#branches[@]} -eq 0 ]]; then
        echo "No branches found matching: $1"
        return 1
    fi

    # Separate merged and unmerged branches
    local merged_branches=()
    local unmerged_branches=()

    for branch in "${branches[@]}"; do
        if [[ "$branch" == "$current_branch" ]]; then
            continue
        fi

        # Check if branch is fully merged
        if git branch --merged | grep -q "^[* ]*${branch}$"; then
            merged_branches+=("$branch")
        else
            unmerged_branches+=("$branch")
        fi
    done

    # Check if current branch is in the list
    local current_in_list=false
    for branch in "${branches[@]}"; do
        if [[ "$branch" == "$current_branch" ]]; then
            current_in_list=true
            break
        fi
    done

    # Show summary
    echo "Found ${#branches[@]} branch(es) matching '$1':"

    if [[ ${#merged_branches[@]} -gt 0 ]]; then
        echo ""
        echo "Merged branches (safe to delete):"
        printf '  %s\n' "${merged_branches[@]}"
    fi

    if [[ ${#unmerged_branches[@]} -gt 0 ]]; then
        echo ""
        echo "⚠️  Unmerged branches (require force delete):"
        printf '  %s\n' "${unmerged_branches[@]}"
    fi

    if [[ "$current_in_list" == true ]]; then
        echo ""
        echo "⚠️  Current branch '$current_branch' will be skipped."
    fi

    if [[ ${#merged_branches[@]} -eq 0 && ${#unmerged_branches[@]} -eq 0 ]]; then
        echo ""
        echo "No branches to delete (current branch cannot be deleted)."
        return 0
    fi

    echo ""

    # Confirmation prompt
    read -p "Delete these branches? (y/N): " confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Delete merged branches
        for branch in "${merged_branches[@]}"; do
            git branch -d "$branch"
        done

        # Delete unmerged branches with force
        for branch in "${unmerged_branches[@]}"; do
            git branch -D "$branch"
        done

        echo "Done."
    else
        echo "Cancelled."
    fi
}

function search() {
  history | grep -i "$1"
}

function restoredb() {
    if [[ "$1" == "help" || "$1" == "--help" || "$1" == "-h" ]]; then
        restoredb_help
        return 0
    fi

    if [[ "$1" == "clean" || "$1" == "-cl" ]]; then
        cleanup_old_backups
        return 0
    fi

    if [[ "$1" == "dates" || "$1" == "--dates" || "$1" == "-d" ]]; then
        echo "Available backup dates in /c/Temp:"
        shopt -s nullglob

        for file in /c/Temp/K_HamaspikLive-*.bak; do
            filename=$(basename "$file")
            # Extract date part: removes prefix and suffix
            date_part=${filename#K_HamaspikLive-}
            date_part=${date_part%.bak}
            echo "  $date_part"
        done
        shopt -u nullglob
        return 0
    fi

    local backup_path="/q/HKC/K_HamaspikLive.bak"
    local temp_path="/c/Temp/K_HamaspikLive.bak"
    local sql_script="$HOME/Documents/Useful SQL/Restore-DB.sql"
    local arg="$1"
    local backup_file="$temp_path"  # Default
	echo "======================================================================================="
    echo " WARNING: Do NOT cancel, stop, or interrupt this operation once it begins!"
    echo "          Interrupting database restore can cause the database to remain inaccessible,"
    echo "          or result in data corruption. Please let the process finish."
    echo "======================================================================================="

    echo "[$(date)] Starting restoredb function..."

    if [[ "$1" == "last" || "$1" == "--last" || "$1" == "-l" ]]; then
        echo "[$(date)] Using existing $temp_path without modifying it."
        if [[ ! -f "$temp_path" ]]; then
            echo "[$(date)] Error: No temp backup found at $temp_path!"
            return 1
        fi
	
	elif [[ "$1" == "copy" || "$1" == "--copy" || "$1" == "-cp" ]]; then
         # Archive the current backup if exists
        if [[ -f "$temp_path" ]]; then
            local lastmod=$(date -r "$temp_path" +"%m-%d")
            local renamed="${temp_path%.*}-$lastmod.bak"
            echo "[$(date)] Existing backup found at $temp_path. Renaming to $renamed..."
            mv "$temp_path" "$renamed"
            echo "[$(date)] Renamed existing backup to $renamed."
        else
            echo "[$(date)] No existing backup at $temp_path to rename."
        fi

        echo "[$(date)] Copying $backup_path to $temp_path..."
        cp "$backup_path" "$temp_path"
        if [[ $? -eq 0 ]]; then
            echo "[$(date)] Copy complete."
			return 1
        else
            echo "[$(date)] Error: Copy failed!"
            return 1
        fi
		

    elif [[ -n "$arg" ]]; then
        # Restore from a dated backup
        local dated_backup="${temp_path%.*}-$arg.bak"
        if [[ -f "$dated_backup" ]]; then
            echo "[$(date)] Restoring from dated backup: $dated_backup"
            backup_file="$dated_backup"
        else
            echo "[$(date)] Error: No backup found for the specified date ($arg): $dated_backup"
            return 1
        fi

    else
        # Archive the current backup if exists
        if [[ -f "$temp_path" ]]; then
            local lastmod=$(date -r "$temp_path" +"%m-%d")
            local renamed="${temp_path%.*}-$lastmod.bak"
            echo "[$(date)] Existing backup found at $temp_path. Renaming to $renamed..."
            mv "$temp_path" "$renamed"
            echo "[$(date)] Renamed existing backup to $renamed."
        else
            echo "[$(date)] No existing backup at $temp_path to rename."
        fi

        echo "[$(date)] Copying $backup_path to $temp_path..."
        cp "$backup_path" "$temp_path"
        if [[ $? -eq 0 ]]; then
            echo "[$(date)] Copy complete."
        else
            echo "[$(date)] Error: Copy failed!"
            return 1
        fi
        backup_file="$temp_path"
    fi

    # Just extract the file name for the SQL script variable
    local backup_filename=$(basename "$backup_file")
    echo "[$(date)] Using backup file name for SQL: $backup_filename"

    echo "[$(date)] Running SQL restore script with Windows Authentication, backup_filename: $backup_filename"
    sqlcmd -S "HKCPC385\\SQLEXPRESS" -E -i "$sql_script" -v backup_filename="$backup_filename"
    if [[ $? -eq 0 ]]; then
        echo "[$(date)] Database restore script completed successfully."
    else
        echo "[$(date)] Error: Database restore script failed!"
        return 1
    fi

    echo "[$(date)] restoredb function finished."
}

function restoredb_help() {
    echo "Usage: restoredb [DATE|l|dates|help]"
    echo
    echo "Options:"
    echo "  DATE        Restore the database from the backup taken on the given date."
    echo "              Date format: m-d (e.g. 2-9 for Feb 9)"
    echo "              Example: restoredb 2-9      # Restores from /c/Temp/K_HamaspikLive-2-9.bak"
    echo "  last, -l    Restore the database from the existing K_HamaspikLive.bak in /c/Temp/."
    echo "              Example: restoredb l"
    echo "  dates, -d   List all available dated backup files in /c/Temp."
    echo "              Example: restoredb dates"
    echo "  clean, -cl  Remove all backups older than 1 month in /c/Temp."
    echo "              Example: restoredb clean"
	echo "  copy, -cp   Create a dated backup of the existing temp file (if any), copy the main backup to the temp location, but don't restore"
    echo "              Example: restoredb copy"
    echo "  help, -h,   Show this help message."
    echo
    echo "No argument:  Create a dated backup of the existing temp file (if any), copy the main backup to the temp location, and restore."
    echo "              Example: restoredb"
    echo
}

function cleanup_old_backups() {
    local backup_dir="/c/Temp"
    local pattern="K_HamaspikLive-*.bak"
    local days_old=30

    echo "[$(date)] Scanning $backup_dir for backups older than $days_old days..."

    # Capture matching old files in an array
    mapfile -t old_files < <(find "$backup_dir" -type f -name "$pattern" -mtime +$days_old)

    if [[ ${#old_files[@]} -eq 0 ]]; then
        echo "[$(date)] No old backups found. Nothing to delete."
        return 0
    fi

    echo "[$(date)] The following backups are older than $days_old days:"
    for f in "${old_files[@]}"; do
        echo "    $f"
    done

    echo -n "Delete ALL the above files? [y/N]: "
    read -r confirm

    if [[ $confirm =~ ^[Yy]$ ]]; then
        echo "[$(date)] Deleting files..."
        for f in "${old_files[@]}"; do
            echo "Deleting: $f"
            rm -v "$f"
        done
        echo "[$(date)] Cleanup complete."
    else
        echo "Aborted. No files were deleted."
    fi
}

complete -d mkcd

# Enable filename completion for restoredb
complete -f restoredb

# Enable branch name completion for gcb
_git_branch_names() {
    # Get a list of branches, clean up output, and match the current word
    local cur="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=( $(git branch --all | sed 's/^[* ]*//' | grep "^$cur") )
}

complete -F _git_branch_names gcb



EOF

# Append the gcb function with username
cat >> /tmp/new_functions <<EOF
function gcb() {
    if [[ "\$1" == "b" ]]; then
        git checkout -b Users/${GIT_BRANCH_USER}/bugs/"\$2"
    elif [[ "\$1" == "e" ]]; then
        git checkout -b Users/${GIT_BRANCH_USER}/epics/"\$2"
    elif [[ "\$1" == "h" ]]; then
        echo "Usage: gcb <b|e> <branch-name>"
        echo "  b = Bug branch"
        echo "  e = Epic branch"
    else
        git checkout -b "\$1"
    fi
}


function help_functions() {
    local target="$1"
    if [[ -z "$target" ]]; then
        cat <<EOF
Available custom shell functions and aliases:

  gcs <branch-pattern>              - Quick-switch to branch matching pattern.
  gbdel <branch-pattern>            - Delete branches matching (with safety/confirm).
  gcb <b|e|h|other> <branch-name>   - Create & checkout branches by convention.
  search <pattern>                  - Grep Bash history for the pattern.
  restoredb [DATE|l|dates|...]      - Restore/Manage SQL database backups.
  restoredb_help                    - Show full usage for restoredb.
  cleanup_old_backups               - Remove old dated backup files.
  Aliases: gl gc gp gst gd gf gb repos restart gpsup gbd 1 .. ... .... ll lsa lla grs dev data gco addalias ga gddev gddata sweep gt gtl gtd gtp gts

Run:
  help_functions <function-or-alias>

  - to get more details about any listed function or alias.
EOF
        return 0
    fi

    case "$target" in
        gcs)
            cat <<EOF
gcs <branch-pattern>
  Quickly check out the branch matching <branch-pattern>.
  - If one match, immediately switches to it.
  - If multiple, lists them and aborts.
Example:
  gcs feat      # Jumps to first branch matching 'feat'
EOF
            ;;
        gbdel)
            cat <<EOF
gbdel <branch-pattern>
  Deletes branches matching the pattern (but not the current branch).
  - Merged branches: deleted safely (git branch -d).
  - Unmerged: lists, asks for confirmation, force deletes (git branch -D).
  - Prompts before deleting. Skips your current checked-out branch.
Example:
  gbdel temp
EOF
            ;;
        gcb)
            cat <<EOF
gcb <b|e|h|other> <branch-name>
  Checks out a new branch using username convention if b/e:
    b: Users/<username>/bugs/<branch-name>
    e: Users/<username>/epics/<branch-name>
    h: Print help on gcb usage
    other: fallback to git checkout -b <value>
Example:
  gcb b JIRA-123
EOF
            ;;
        search)
            cat <<EOF
search <pattern>
  Search your Bash history for the given pattern, case-insensitive.
Example:
  search ssh
EOF
            ;;
        restoredb)
            cat <<EOF
restoredb [DATE|l|dates|help|clean|copy]
  Restores 'Hamaspik_Dev' database from recent backup or by date.
  WARNING: Do NOT cancel, stop, or interrupt once started!
Options:
  <DATE>     Restore from /c/Temp/K_HamaspikLive-<DATE>.bak (DATE=m-d)
  l|-l       Use latest in /c/Temp/K_HamaspikLive.bak
  dates|-d   List available backup dates
  clean|-cl  Remove old dated backup files
  copy|-cp   Copy main backup to temp location, don't restore
  help|-h    See detailed usage (or run: restoredb_help)
EOF
            ;;
        restoredb_help)
            cat <<EOF
restoredb_help
  Shows detailed help and examples for using the restoredb function.
EOF
            ;;
        cleanup_old_backups)
            cat <<EOF
cleanup_old_backups
  Finds /c/Temp/K_HamaspikLive-*.bak files >30 days old, asks for confirmation, deletes if yes.
EOF
            ;;
        gl|gc|gp|gst|gd|gf|gb|repos|restart|gpsup|gbd|1|..|...|....|ll|lsa|lla|grs|dev|data|gco|addalias|ga|gddev|gddata|sweep|gt|gtl|gtd|gtp|gts)
            {
                declare -A alias_detail=(
["gl"]="git pull"
["gc"]="git commit"
["gp"]="git push"
["gst"]="git status"
["gd"]="git diff"
["gf"]="git fetch"
["gb"]="git branch"
["repos"]="cd \$HOME/source/repos"
["restart"]="source ~/.bashrc"
["gpsup"]="git push --set-upstream origin \$(git branch --show-current)"
["gbd"]="git branch --delete"
["1"]="cd -"
[".."]="cd .."
["..."]="cd ../.."
["...."]="cd ../../.."
["ll"]="ls -lh"
["lsa"]="ls -a"
["lla"]="ls -lha"
["grs"]="git restore"
["dev"]="git checkout _Dev"
["data"]="git checkout _Data"
["gco"]="git checkout"
["addalias"]="vim ~/.bashrc"
["ga"]="git add"
["gddev"]="git diff origin/_Dev"
["gddata"]="git diff origin/_Data"
["sweep"]="git branch --merged | grep -v \"\\*\\|Kings_Master\\|_Dev\\|_Data\" | xargs -n 1 git branch -d"
["gt"]="git stash"
["gtl"]="git stash list"
["gtd"]="git stash drop"
["gtp"]="git stash pop"
["gts"]="git stash show -p"
                )
                desc=${alias_detail[$target]}
                echo "$target : $desc"
            }
            ;;
        *)
            echo "No detailed help found for '$target'. Try 'help_functions' for a list."
            ;;
    esac
}


# END CUSTOM FUNCTIONS

EOF

# Insert aliases into .bashrc, removing any previous block first
sed -i '/# BEGIN CUSTOM ALIASES/,/# END CUSTOM ALIASES/d' "$BASHRC"
cat /tmp/new_aliases >> "$BASHRC"

# Create/update .bash_functions
sed -i '/# BEGIN CUSTOM FUNCTIONS/,/# END CUSTOM FUNCTIONS/d' "$FUNCFILE" 2>/dev/null
cat /tmp/new_functions >> "$FUNCFILE"

# Make sure .bashrc sources .bash_functions (if not already)
if ! grep -q 'source ~/.bash_functions' "$BASHRC"; then
    echo -e "\n# Source custom functions\nif [ -f ~/.bash_functions ]; then\n    source ~/.bash_functions\nfi" >> "$BASHRC"
fi

# Ensure shopt -s autocd is present only once
grep -qxF 'shopt -s autocd' "$BASHRC" || echo 'shopt -s autocd' >> "$BASHRC"

echo "Custom aliases and functions updated!"
