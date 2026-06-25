# ~/.config/shell/common.sh
# Shared config sourced by .zshrc (bash-compatible if you source it yourself)
# Dotfiles: github.com/dannyirwin/dotfiles

# ─────────────────────────────────────────────
#  XDG base dirs (good hygiene)
# ─────────────────────────────────────────────
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# ─────────────────────────────────────────────
#  PATH
# ─────────────────────────────────────────────
# Homebrew (Mac Intel / Apple Silicon)
if [[ -d "/opt/homebrew/bin" ]]; then
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
elif [[ -d "/usr/local/bin" ]]; then
  export PATH="/usr/local/bin:$PATH"
fi

# Local bin
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# ─────────────────────────────────────────────
#  Editor
# ─────────────────────────────────────────────
if command -v nvim &>/dev/null; then
  export EDITOR="nvim"
  export VISUAL="nvim"
elif command -v vim &>/dev/null; then
  export EDITOR="vim"
  export VISUAL="vim"
fi

# ─────────────────────────────────────────────
#  Language / locale
# ─────────────────────────────────────────────
if command -v locale &>/dev/null; then
  for loc in en_US.UTF-8 C.UTF-8 en_US.utf8 C.utf8; do
    if locale -a 2>/dev/null | grep -qi "^${loc}$"; then
      export LANG="$loc"
      export LC_ALL="$loc"
      break
    fi
  done
fi

# ─────────────────────────────────────────────
#  History
# ─────────────────────────────────────────────
export HISTSIZE=50000
export HISTFILESIZE=50000
export HISTCONTROL="ignoreboth:erasedups"

# ─────────────────────────────────────────────
#  Colors
# ─────────────────────────────────────────────
export CLICOLOR=1
if [[ -z "${TMUX:-}" && "${TERM:-}" != tmux* ]]; then
  export TERM="xterm-256color"
fi
export COLORTERM="truecolor"

# ls colors (GNU on Linux, BSD on Mac)
if ls --color=auto &>/dev/null 2>&1; then
  alias ls='ls --color=auto'
else
  alias ls='ls -G'
fi

# ─────────────────────────────────────────────
#  Aliases — navigation
# ─────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# ─────────────────────────────────────────────
#  Aliases — ls
# ─────────────────────────────────────────────
alias l='ls -lh'
alias la='ls -lha'
alias ll='ls -lh'
alias lt='ls -lht'          # sort by time
alias lS='ls -lhS'          # sort by size

# ─────────────────────────────────────────────
#  Aliases — git
# ─────────────────────────────────────────────
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'
alias gds='git diff --staged'
alias gco='git checkout'
alias gb='git branch'
alias gst='git stash'
alias gstp='git stash pop'

# ─────────────────────────────────────────────
#  Aliases — misc
# ─────────────────────────────────────────────
alias v='$EDITOR'
alias vi='$EDITOR'
alias vim='$EDITOR'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias df='df -h'
alias du='du -h'
alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias reload='source ~/.zshrc 2>/dev/null || source ~/.bashrc'

# ─────────────────────────────────────────────
#  Functions
# ─────────────────────────────────────────────

# mkcd — make dir and cd into it
mkcd() { mkdir -p "$1" && cd "$1" || return 1; }

# up N — go up N directories
up() {
  local count="${1:-1}"
  local path=""
  for _ in $(seq 1 "$count"); do path="../$path"; done
  cd "$path" || return 1
}

# extract — universal archive extractor
extract() {
  if [[ -f "$1" ]]; then
    case "$1" in
      *.tar.bz2)   tar xjf "$1"   ;;
      *.tar.gz)    tar xzf "$1"   ;;
      *.tar.xz)    tar xJf "$1"   ;;
      *.tar.zst)   tar --zstd -xf "$1" ;;
      *.bz2)       bunzip2 "$1"   ;;
      *.gz)        gunzip "$1"    ;;
      *.zip)       unzip "$1"     ;;
      *.7z)        7z x "$1"      ;;
      *.rar)       unrar e "$1"   ;;
      *)           echo "'$1' cannot be extracted" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# ff — fuzzy find file and open in editor
ff() { $EDITOR "$(find . -type f | fzf)"; }

# path — print PATH entries one per line
path() { echo "$PATH" | tr ':' '\n'; }

# ─────────────────────────────────────────────
#  Optional: fzf
# ─────────────────────────────────────────────
if command -v fzf &>/dev/null; then
  export FZF_DEFAULT_OPTS="
    --height 40%
    --layout=reverse
    --border=rounded
    --color=bg+:#283457,bg:#1a1b26,spinner:#73daca,hl:#bb9af7
    --color=fg:#c0caf5,header:#7aa2f7,info:#7dcfff,pointer:#7aa2f7
    --color=marker:#9ece6a,fg+:#c0caf5,prompt:#7aa2f7,hl+:#7aa2f7
  "
  _fzf_fd=""
  if command -v fd &>/dev/null; then
    _fzf_fd="fd"
  elif command -v fdfind &>/dev/null; then
    _fzf_fd="fdfind"
  elif [[ -x "$HOME/.local/bin/fd" ]]; then
    _fzf_fd="$HOME/.local/bin/fd"
  fi
  if [[ -n "$_fzf_fd" ]]; then
    export FZF_DEFAULT_COMMAND="$_fzf_fd --type f --hidden --follow --exclude .git"
    export FZF_ALT_C_COMMAND="$_fzf_fd --type d --hidden --follow --exclude .git"
  fi
  unset _fzf_fd
fi

# ─────────────────────────────────────────────
#  Optional: zoxide (smarter cd)
# ─────────────────────────────────────────────
if command -v zoxide &>/dev/null; then
  if [[ -n "${ZSH_VERSION:-}" ]]; then
    eval "$(zoxide init zsh --cmd cd)"
  elif [[ -n "${BASH_VERSION:-}" ]]; then
    eval "$(zoxide init bash --cmd cd)"
  fi
fi
