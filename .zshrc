# ============================================================================
# Powerlevel10k Instant Prompt (must stay at top)
# ============================================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ============================================================================
# XDG Base Directories
# ============================================================================
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# ============================================================================
# OS Detection
# ============================================================================
case "$(uname -s)" in
  Linux)
    if [[ -f /etc/arch-release ]]; then
      export CURRENT_OS="arch"
    elif [[ -f /etc/fedora-release ]]; then
      export CURRENT_OS="fedora"
    else
      export CURRENT_OS="linux"
    fi
    ;;
  Darwin)
    export CURRENT_OS="macos"
    ;;
esac

# ============================================================================
# PATH
# ============================================================================
typeset -U path

path=(
  "$HOME/.local/bin"
  "$HOME/bin"
  "/usr/local/bin"
  $path
)

# Homebrew (macOS / Linuxbrew)
if [[ "$CURRENT_OS" == "macos" ]]; then
  if [[ -d "/opt/homebrew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -d "/usr/local/Homebrew" ]]; then
    eval "$(/usr/local/Homebrew/bin/brew shellenv)"
  fi
elif [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

[[ -d "$HOME/.cargo/bin" ]] && path=("$HOME/.cargo/bin" $path)

if command -v go &>/dev/null; then
  export GOPATH="${GOPATH:-$HOME/go}"
  path=("$GOPATH/bin" $path)
fi

if [[ -d "$HOME/.local/share/pnpm" ]]; then
  export PNPM_HOME="$HOME/.local/share/pnpm"
  path=("$PNPM_HOME" $path)
fi

export PATH

# ============================================================================
# Oh My Zsh & Plugins
# ============================================================================
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Base plugins (all platforms)
# NOTE: fzf-tab must come before zsh-autosuggestions and fast-syntax-highlighting
plugins=(
  git
  fzf
  fzf-tab
  dotenv
  vscode
  cp
  colorize
  encode64
  zsh-autosuggestions
  fast-syntax-highlighting
)

# Container tools (only if installed)
command -v docker &>/dev/null && plugins+=(docker docker-compose)
command -v kubectl &>/dev/null && plugins+=(kubectl)
command -v minikube &>/dev/null && plugins+=(minikube)

# Ruby (only if rbenv is installed)
command -v rbenv &>/dev/null && plugins+=(bundler rake rbenv ruby)

# macOS-specific
[[ "$CURRENT_OS" == "macos" ]] && plugins+=(macos brew)

# Autojump only as fallback if zoxide is missing
! command -v zoxide &>/dev/null && command -v autojump &>/dev/null && plugins+=(autojump)

source "$ZSH/oh-my-zsh.sh"

# ============================================================================
# History
# ============================================================================
HISTFILE="$XDG_DATA_HOME/zsh/.zhistory"
SAVEHIST=1000000
HISTSIZE=1000000
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_verify

# ============================================================================
# Shell Options
# ============================================================================
setopt correct           # autocorrect command typos
setopt autocd            # cd by typing directory name
setopt extendedglob      # extended globbing patterns
setopt nocaseglob        # case-insensitive globbing
setopt numericglobsort   # sort file1 file2 file10 correctly
setopt rcexpandparam     # array expansion with params
setopt nocheckjobs       # don't warn about running jobs on exit
setopt nobeep            # no terminal beep

# Auto-pick up new executables in PATH without restart
zstyle ':completion:*' rehash true

# GPG agent
export GPG_TTY=$(tty)

# ============================================================================
# Editor & Pagers
# ============================================================================
if command -v nvim &>/dev/null; then
  export EDITOR="nvim"
  alias vim=nvim
  alias vi=nvim
elif command -v vim &>/dev/null; then
  export EDITOR="vim"
fi

# Use bat as the manpage pager (colorized, syntax-highlighted)
if command -v bat &>/dev/null; then
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# ============================================================================
# Aliases
# ============================================================================
if command -v kubectl &>/dev/null; then
  alias k=kubectl
  compdef __start_kubectl k
fi

case "$CURRENT_OS" in
  macos)
    alias flush="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
    ;;
  arch|fedora|linux)
    alias open="xdg-open"
    ;;
esac

# eza replaces ls (icons, git status, color)
if command -v eza &>/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lh --icons --git --group-directories-first'
  alias la='eza -lah --icons --git --group-directories-first'
  alias tree='eza --tree --icons'
else
  case "$CURRENT_OS" in
    macos)        alias ls="ls -G" ;;
    arch|fedora|linux) alias ls="ls --color=auto" ;;
  esac
fi

# bat replaces cat (syntax highlighting); keep raw cat available as `\cat`
command -v bat &>/dev/null && alias cat='bat --paging=never'

# ============================================================================
# Tools
# ============================================================================

# Zoxide (replaces autojump)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# direnv (per-directory env vars via .envrc)
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

# NVM
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Kubectl completion (if not already loaded by plugin)
if command -v kubectl &>/dev/null && [[ -z "${_comps[kubectl]}" ]]; then
  source <(kubectl completion zsh)
fi

# FZF (platform-aware paths)
case "$CURRENT_OS" in
  arch)
    [ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
    [ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh
    ;;
  fedora)
    [ -f /usr/share/fzf/shell/key-bindings.zsh ] && source /usr/share/fzf/shell/key-bindings.zsh
    ;;
  macos)
    [ -f "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/fzf/shell/key-bindings.zsh" ] && \
      source "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/fzf/shell/key-bindings.zsh"
    [ -f "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/fzf/shell/completion.zsh" ] && \
      source "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/fzf/shell/completion.zsh"
    ;;
esac

# FZF defaults — use fd (faster, respects .gitignore) and bat preview
if command -v fd &>/dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi
if command -v bat &>/dev/null; then
  export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
fi

# fzf-tab styling (only if plugin is loaded)
if [[ -n "${functions[fzf-tab-complete]}" ]]; then
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
  zstyle ':completion:*:descriptions' format '[%d]'
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath 2>/dev/null || ls --color=always $realpath'
  zstyle ':fzf-tab:complete:*:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null || eza --color=always --icons $realpath 2>/dev/null'
  zstyle ':fzf-tab:*' switch-group ',' '.'
fi

# Envman
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

# switch.sh
[ -s /usr/local/bin/switch.sh ] && source /usr/local/bin/switch.sh

# ============================================================================
# Powerlevel10k Config
# ============================================================================
[[ -f "$ZDOTDIR/.p10k.zsh" ]] && source "$ZDOTDIR/.p10k.zsh" || \
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
