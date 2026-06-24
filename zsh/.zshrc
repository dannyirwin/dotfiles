# ~/.zshrc
# Dotfiles: github.com/dannyirwin/dotfiles

# ─────────────────────────────────────────────
#  Source shared config
# ─────────────────────────────────────────────
[[ -f "$HOME/.config/shell/common.sh" ]] && source "$HOME/.config/shell/common.sh"

# ─────────────────────────────────────────────
#  Zsh history
# ─────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY

# ─────────────────────────────────────────────
#  Options
# ─────────────────────────────────────────────
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt GLOB_DOTS
setopt CORRECT
setopt INTERACTIVE_COMMENTS

# ─────────────────────────────────────────────
#  Key bindings (emacs-style)
# ─────────────────────────────────────────────
bindkey -e
bindkey '^[[A' history-search-backward  # up arrow
bindkey '^[[B' history-search-forward   # down arrow
bindkey '^[[H' beginning-of-line        # home
bindkey '^[[F' end-of-line              # end
bindkey '^[[3~' delete-char             # delete

# ─────────────────────────────────────────────
#  Zinit — plugin manager
# ─────────────────────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

if [[ ! -f "$ZINIT_HOME/zinit.zsh" ]]; then
  if [[ -d "$ZINIT_HOME" ]]; then
    rm -rf "$ZINIT_HOME"
  fi
  echo "Installing Zinit..."
  mkdir -p "$(dirname "$ZINIT_HOME")"
  if ! git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"; then
    rm -rf "$ZINIT_HOME" 2>/dev/null
    echo "Zinit install failed — shell will start without plugins" >&2
  fi
fi

if [[ -f "$ZINIT_HOME/zinit.zsh" ]]; then
  source "$ZINIT_HOME/zinit.zsh"
  autoload -Uz _zinit
  (( ${+_comps} )) && _comps[zinit]=_zinit

  # ── Plugins ───────────────────────────────────
  zinit light zsh-users/zsh-completions
  zinit light MichaelAquilina/zsh-you-should-use

  zinit ice wait"0a"
  zinit light Aloxaf/fzf-tab

  zinit ice wait"0a"
  zinit light zsh-users/zsh-autosuggestions

  zinit ice wait"0a"
  zinit light zsh-users/zsh-syntax-highlighting

  # ── Plugin config ─────────────────────────────
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#565f89"
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
  bindkey '^]' autosuggest-accept

  export YSU_MESSAGE_POSITION="after"
  export YSU_MODE=ALL
fi

# ─────────────────────────────────────────────
#  Completion
# ─────────────────────────────────────────────
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi
[[ -f "$ZINIT_HOME/zinit.zsh" ]] && zinit cdreplay -q

zstyle ':fzf-tab:*' fzf-flags \
  --color="bg+:#283457,bg:#1a1b26,border:#565f89,hl:#bb9af7,fg:#c0caf5,fg+:#c0caf5,hl+:#7aa2f7,pointer:#7aa2f7"
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -G $realpath 2>/dev/null || ls --color=auto $realpath 2>/dev/null || ls $realpath'
zstyle ':completion:*' menu no
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}No matches for: %d%f'
zstyle ':completion:*:git-checkout:*' sort false

# ─────────────────────────────────────────────
#  Prompt
# ─────────────────────────────────────────────
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
else
  autoload -Uz vcs_info
  precmd() { vcs_info }
  zstyle ':vcs_info:git:*' formats ' %F{#9ece6a}(%b)%f'
  setopt PROMPT_SUBST
  PROMPT='%F{#7aa2f7}%~%f${vcs_info_msg_0_} %F{#7dcfff}❯%f '
fi

# ─────────────────────────────────────────────
#  fzf key bindings
# ─────────────────────────────────────────────
if command -v fzf &>/dev/null; then
  if fzf --zsh &>/dev/null; then
    source <(fzf --zsh)
  else
    for f in \
      /opt/homebrew/opt/fzf/shell/key-bindings.zsh \
      /usr/local/opt/fzf/shell/key-bindings.zsh \
      /usr/share/doc/fzf/examples/key-bindings.zsh; do
      [[ -f "$f" ]] && { source "$f"; break; }
    done
  fi
fi

# ─────────────────────────────────────────────
#  Local overrides
# ─────────────────────────────────────────────
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
