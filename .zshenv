# ============================================================================
# ~/.zshenv — install this file at $HOME/.zshenv (symlink or copy).
#
# This is the ONLY zsh file read before zsh decides which .zshrc to source,
# so it's where ZDOTDIR has to be set. Without it, zsh reads /etc/zshrc and
# $HOME/.zshrc and never finds this repo's config.
#
# Install (symlink keeps it in sync with the repo):
#   ln -sf "$HOME/.config/zsh/.zshenv" "$HOME/.zshenv"
# ============================================================================

export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

# Rust toolchain (no-op if cargo isn't installed)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
