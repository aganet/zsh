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
# OS Detection (consumed by pluginrc / aliasrc / PATH / FZF setup)
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
# Modular config — split into three files
#   pluginrc → Oh My Zsh + plugin list (loads OMZ, must come first)
#   optionrc → setopt + history settings
#   aliasrc  → all aliases incl. devops shortcuts (after OMZ so compdef works)
# ============================================================================
[ -f "$ZDOTDIR/pluginrc" ] && source "$ZDOTDIR/pluginrc"
[ -f "$ZDOTDIR/optionrc" ] && source "$ZDOTDIR/optionrc"
[ -f "$ZDOTDIR/aliasrc"  ] && source "$ZDOTDIR/aliasrc"

# ============================================================================
# Editor & MANPAGER (env vars — matching aliases live in aliasrc)
# ============================================================================
if command -v nvim &>/dev/null; then
  export EDITOR="nvim"
elif command -v vim &>/dev/null; then
  export EDITOR="vim"
fi

# bat as the manpage pager (colorized, syntax-highlighted)
if command -v bat &>/dev/null; then
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# ============================================================================
# Tool integrations
# ============================================================================

# Zoxide — smart `cd` with frecency-based jumping
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# direnv (per-directory env vars via .envrc)
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

# mise - polyglot version manager (replaces nvm / pyenv / rbenv / asdf).
# Activates in ~5 ms vs NVM's ~950 ms; auto-switches versions on cd.
command -v mise &>/dev/null && eval "$(mise activate zsh)"

# Kubectl completion fallback (only if OMZ kubectl plugin didn't load it)
if command -v kubectl &>/dev/null && [[ -z "${_comps[kubectl]}" ]]; then
  source <(kubectl completion zsh)
fi

# FZF — platform-aware install paths
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

# ============================================================================
# Host-local overrides (machine-specific tweaks)
# ============================================================================
[[ -f "$ZDOTDIR/local.zsh" ]] && source "$ZDOTDIR/local.zsh"
eval "$(mise activate zsh)"
