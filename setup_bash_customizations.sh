#!/bin/bash

# Define which files we work with
BASHRC="$HOME/.bashrc"
FUNCFILE="$HOME/.bash_functions"

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
alias sweep='git branch --merged | grep -v "\*\|Master\|Main\|Dev" | xargs -n 1 git branch -d'
alias gt='git stash'
alias gtl='git stash list'
alias gtd='git stash drop'
alias gtp='git stash pop'
alias gts='git stash show -p'
alias glo='git log --oneline --decorate'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias wip='git add . && git commit -m "WIP"'
alias unstage='git restore --staged'

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

function help_functions() {
    local target="$1"
    if [[ -z "$target" ]]; then
        cat <<'EOF'
Available custom shell functions and aliases:

Git Functions:
  gcb <b|e|h> <name>   Create branch by convention (Bug, Epic).
  gcs <pattern>        Switch to a branch matching a pattern.
  gbdel <pattern>      Interactively delete local branches matching a pattern.
  search <pattern>     Search command history.
  help_functions [cmd] Show this help, or details for a specific command.

Git Aliases:
  Workflow:
    gl       git pull
    gp       git push
    gpsup    git push --set-upstream origin <current-branch>
    gf       git fetch
    ga       git add
    gc       git commit
    wip      git add . && git commit -m "WIP"
    grs      git restore
    unstage  git restore --staged

  Status & Logging:
    gst      git status
    gd       git diff
    glo      git log --oneline --decorate
    glog     git log --oneline --decorate --graph
    gloga    git log --oneline --decorate --graph --all

  Branching:
    gb       git branch
    gco      git checkout
    gbd      git branch --delete
    sweep    Delete all local merged branches (except main/master/dev).
    dev      git checkout _Dev
    data     git checkout _Data

  Stashing:
    gt       git stash
    gtl      git stash list
    gtd      git stash drop
    gtp      git stash pop
    gts      git stash show -p

Shell Aliases:
  Navigation:
    repos    cd $HOME/source/repos
    ..       cd ..
    ...      cd ../..
    ....     cd ../../..
    1        cd - (go to previous directory)

  Listing:
    ll       ls -lh
    lsa      ls -a
    lla      ls -lha

  Configuration:
    restart    source ~/.bashrc
    addalias   vim ~/.bashrc

Run 'help_functions <command>' for more details.
EOF
        return 0
    fi

    # Case statement for detailed help on each command
    case "$target" in
        gcb)
            cat <<'EOF'
gcb <b|e|h|other> <branch-name>
  Create and checkout a new branch with a conventional name.
  - 'b': Creates Users/<user>/bugs/<branch-name>
  - 'e': Creates Users/<user>/epics/<branch-name>
  - 'h': Prints this help message.
  - Any other value is passed directly to 'git checkout -b'.
Example:
  gcb b fix-login-bug  # Creates Users/sholoms/bugs/fix-login-bug
EOF
            ;;
        gcs)
            cat <<'EOF'
gcs <branch-pattern>
  Quickly checkout a branch that matches a search pattern.
  - If exactly one branch matches, it switches to it.
  - If multiple branches match, it lists them and prompts for a more specific pattern.
Example:
  gcs login  # Switches to 'feature/login' if it's the only match
EOF
            ;;
        gbdel)
            cat <<'EOF'
gbdel <branch-pattern>
  Interactively find and delete local branches matching a pattern.
  - Lists merged (safe to delete) and unmerged (force delete required) branches.
  - Skips the current branch automatically.
  - Prompts for confirmation before deleting any branches.
Example:
  gbdel old-feature
EOF
            ;;
        search)
            cat <<'EOF'
search <pattern>
  Searches your command history for a specific pattern (case-insensitive).
Example:
  search docker  # Shows all previous commands containing 'docker'
EOF
            ;;
        sweep)
            echo "sweep : Deletes all local branches that have been merged into the current branch, ignoring protected branches like Master, Main, and Dev."
            ;;
        wip)
            echo "wip : 'git add .' && 'git commit -m \"WIP\"' - Quickly stages all changes and creates a 'Work In Progress' commit."
            ;;
        gpsup)
            echo "gpsup : 'git push --set-upstream origin <current-branch>' - Pushes the current branch to the remote and sets it to track the remote branch."
            ;;
        *)
            # Fallback for aliases to show their definition
            local definition
            definition=$(alias "$target" 2>/dev/null)
            if [[ -n "$definition" ]]; then
                echo "$definition"
            else
                echo "No help available for '$target'. Run 'help_functions' for a full list of commands."
            fi
            ;;
    esac
}

# END CUSTOM FUNCTIONS
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


