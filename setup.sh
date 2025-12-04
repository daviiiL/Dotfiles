#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'
print_header() {
  echo -e "${BOLD}$1${NC}"
}

print_success() {
  echo -e "${GREEN}$1${NC}"
}

print_info() {
  echo -e "${CYAN}$1${NC}"
}

print_warning() {
  echo -e "${YELLOW}$1${NC}"
}

print_error() {
  echo -e "${RED}$1${NC}"
}

print_separator() {
  echo -e "${BLUE}────────────────────────────────────────────────────────${NC}"
}

clear
echo ""
print_error "################################################################"
print_error "#                                                              #"
print_error "# WARNING: This script will not work on non-Arch distributions #"
print_error "#                                                              #"
print_error "################################################################"
echo ""
echo ""

print_separator
print_header "Fetching git submodules..."
print_separator
echo ""
sleep 0.3

git submodule update --init --recursive

sleep 0.3
echo ""
print_separator
print_header "Populating dotfiles to \$HOME/.config..."
print_separator
echo ""
sleep 0.3

SUBMODULE_PATH="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.config/Dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

for module_name in "quickshell" "hypr" "matugen" "wezterm"; do
  if [ -e "$HOME/.config/$module_name" ]; then
    read -p "$(echo -e "${YELLOW}Moving previous $module_name configuration to $BACKUP_DIR/$module_name? Previous config will be overwritten if not backed up... [Y/n]: ${NC}")" -n 1 -r
    REPLY=${REPLY:-Y}
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo ""
      mkdir -p "$BACKUP_DIR"
      mv "$HOME/.config/$module_name" "$BACKUP_DIR/$module_name"
      print_success "Backup complete: $BACKUP_DIR/$module_name"
      echo ""
    else
      echo ""
      rm -rf "$HOME/.config/$module_name"
    fi
  fi

  echo ""

  print_info "Creating symlink for $module_name..."
  ln -s "$SUBMODULE_PATH/config_dots/$module_name" "$HOME/.config/$module_name"
  print_success "$module_name linked..."
done

echo ""
print_separator
print_success "Configurations synced..."
print_separator
echo ""

sleep 0.3
echo ""
print_separator
print_header "Setting up WezTerm..."
print_separator
echo ""
sleep 0.3

WEZTERM_DIR="$SUBMODULE_PATH/gitsources/wezterm"
WEZTERM_BINARY="$WEZTERM_DIR/target/release/wezterm"
LOCAL_BIN="$HOME/.local/bin"
WEZTERM_LINK="$LOCAL_BIN/wezterm"

setup_wezterm_symlink() {
  mkdir -p "$LOCAL_BIN"
  [ -e "$WEZTERM_LINK" ] && rm -f "$WEZTERM_LINK"
  ln -s "$WEZTERM_BINARY" "$WEZTERM_LINK"
  print_success "WezTerm symlink created: $WEZTERM_LINK"
}

if [ -f "$WEZTERM_BINARY" ]; then
  print_info "WezTerm binary found, skipping build..."
  if [ ! -L "$WEZTERM_LINK" ] || [ "$(readlink -f "$WEZTERM_LINK")" != "$(readlink -f "$WEZTERM_BINARY")" ]; then
    setup_wezterm_symlink
  else
    print_success "WezTerm symlink already configured correctly"
  fi
else
  print_info "Building WezTerm from source..."

  command -v rustc &>/dev/null || {
    print_info "Installing Rust..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
  }

  [ ! -d "$WEZTERM_DIR" ] && {
    print_info "Cloning WezTerm repository..."
    git clone --depth=1 --branch=main --recursive https://github.com/wez/wezterm.git "$WEZTERM_DIR"
  }

  cd "$WEZTERM_DIR" || exit 1
  git submodule update --init --recursive
  ./get-deps
  cargo build --release

  if [ $? -eq 0 ]; then
    print_success "WezTerm built..."
    setup_wezterm_symlink
  else
    print_error "WezTerm build failed... Exiting..."
    exit 1
  fi

  cd "$SUBMODULE_PATH" || exit 1
fi

echo ""
print_separator
print_success "Dotfiles setup complete..."
print_success "Reloading Hyprland Configurations..."

hyprctl reload

print_success "DONE"

print_separator
echo ""
