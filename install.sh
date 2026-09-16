#!/bin/zsh
set -e

INSTALL_DIR="$HOME/.maybebun"
REPO="https://raw.githubusercontent.com/h053698/maybebun/main"
ZSHRC="$HOME/.zshrc"

echo "Installing maybebun..."

# Check Bun
if ! command -v bun >/dev/null 2>&1; then
  echo "Error: Bun is required."
  echo "Install Bun first: https://bun.sh"
  exit 1
fi

# Install gum
if ! command -v gum >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    echo "Installing gum..."
    brew install gum
  else
    echo "Error: gum is required."
    echo "Install gum and run this installer again."
    exit 1
  fi
fi

# Download maybebun to a temp file first, so a failed download
# cannot leave a half-written script behind.
mkdir -p "$INSTALL_DIR"
tmp="$(mktemp)"
if ! curl -fsSL "$REPO/maybebun.zsh" -o "$tmp"; then
  rm -f "$tmp"
  echo "Error: failed to download maybebun.zsh"
  exit 1
fi

# Reject a truncated or wrong download before installing it.
if ! zsh -n "$tmp" 2>/dev/null || ! grep -q 'MAYBEBUN_LOADED' "$tmp"; then
  rm -f "$tmp"
  echo "Error: downloaded file is not a valid maybebun.zsh"
  exit 1
fi

mv "$tmp" "$INSTALL_DIR/maybebun.zsh"

# Add to .zshrc
SOURCE_LINE='source "$HOME/.maybebun/maybebun.zsh"'

if [[ -f "$ZSHRC" ]] && grep -Fq "$SOURCE_LINE" "$ZSHRC"; then
  echo "  already sourced from ~/.zshrc"
else
  # Back up before touching an existing .zshrc.
  if [[ -f "$ZSHRC" ]]; then
    backup="$ZSHRC.maybebun-backup.$(date +%Y%m%d%H%M%S)"
    cp "$ZSHRC" "$backup"
    echo "  backed up ~/.zshrc to $(basename "$backup")"
  fi

  printf '\n# maybebun\n%s\n' "$SOURCE_LINE" >> "$ZSHRC"
fi

echo
echo "✓ maybebun installed"
echo "  Restart your shell or run: exec zsh"
