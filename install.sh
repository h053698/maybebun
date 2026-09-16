#!/bin/zsh
set -e

INSTALL_DIR="$HOME/.maybebun"
REPO="https://raw.githubusercontent.com/h053698/maybebun/main"

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

# Download maybebun
mkdir -p "$INSTALL_DIR"
curl -fsSL "$REPO/maybebun.zsh" -o "$INSTALL_DIR/maybebun.zsh"

# Add to .zshrc
SOURCE_LINE='source "$HOME/.maybebun/maybebun.zsh"'

if ! grep -Fq "$SOURCE_LINE" "$HOME/.zshrc" 2>/dev/null; then
  printf '\n# maybebun\n%s\n' "$SOURCE_LINE" >> "$HOME/.zshrc"
fi

echo
echo "✓ maybebun installed"
echo "  Restart your shell or run: exec zsh"
