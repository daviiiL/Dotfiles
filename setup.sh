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

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.config/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

for config_dir in "$DOTFILES_DIR/config_dots"/*; do
  if [ -d "$config_dir" ]; then
    dir_name=$(basename "$config_dir")
    target_path="$HOME/.config/$dir_name"

    if [ -e "$target_path" ]; then
      echo ""
      print_warning "Found existing $dir_name directory. Backing up to $BACKUP_DIR/$dir_name..."
      echo ""

      read -p "$(echo -e ${YELLOW}Do you want to proceed with backing up this folder? \(y/n\): ${NC})" -n 1 -r
      echo ""

      if [[ $REPLY =~ ^[Yy]$ ]]; then
        mkdir -p "$BACKUP_DIR"
        mv "$target_path" "$BACKUP_DIR/$dir_name"
        print_success "Backup complete: $BACKUP_DIR/$dir_name"
        echo ""
      else
        print_warning "Removing existing $dir_name directory without backup..."
        rm -rf "$target_path"
        print_info "Removed $dir_name"
        echo ""
      fi
    fi

    print_info "Creating symlink for $dir_name..."
    ln -s "$config_dir" "$target_path"
    print_success "Linked $dir_name"
  fi
done

echo ""
print_separator
print_success "All dotfiles have been successfully linked!"
print_separator
echo ""

sleep 0.3
echo ""
print_separator
print_header "Setting up WezTerm..."
print_separator
echo ""
sleep 0.3

WEZTERM_DIR="$DOTFILES_DIR/gitsources/wezterm"
WEZTERM_BINARY="$WEZTERM_DIR/target/release/wezterm"
LOCAL_BIN="$HOME/.local/bin"
WEZTERM_LINK="$LOCAL_BIN/wezterm"

if [ -f "$WEZTERM_BINARY" ]; then
  print_info "WezTerm binary already built at $WEZTERM_BINARY"

  if [ -L "$WEZTERM_LINK" ] && [ "$(readlink -f "$WEZTERM_LINK")" == "$(readlink -f "$WEZTERM_BINARY")" ]; then
    print_success "WezTerm symlink already exists and is correct. Skipping setup."
    echo ""
    print_separator
    print_success "WezTerm setup complete!"
    print_separator
    echo ""
  else
    print_info "WezTerm binary exists but symlink needs to be created..."
    mkdir -p "$LOCAL_BIN"

    if [ -L "$WEZTERM_LINK" ]; then
      print_warning "Removing existing wezterm symlink..."
      rm "$WEZTERM_LINK"
    elif [ -e "$WEZTERM_LINK" ]; then
      print_warning "Found existing wezterm file (not a symlink). Backing up..."
      mkdir -p "$BACKUP_DIR"
      mv "$WEZTERM_LINK" "$BACKUP_DIR/wezterm"
    fi

    ln -s "$WEZTERM_BINARY" "$WEZTERM_LINK"
    print_success "Created symlink: $WEZTERM_LINK -> $WEZTERM_BINARY"
    echo ""
    print_separator
    print_success "WezTerm setup complete!"
    print_separator
    echo ""
  fi
else
  print_info "WezTerm needs to be built..."
  echo ""

  if command -v rustc &> /dev/null; then
  print_success "Rust is already installed ($(rustc --version))"
else
  print_info "Rust not detected. Installing via rustup..."
  curl https://sh.rustup.rs -sSf | sh -s -- -y

  source "$HOME/.cargo/env"

  print_success "Rust installed successfully!"
fi

echo ""

  if [ -d "$WEZTERM_DIR" ]; then
    print_info "WezTerm repository already exists at $WEZTERM_DIR"
  else
    print_info "Cloning WezTerm repository..."
    mkdir -p "$DOTFILES_DIR/gitsources"
    git clone --depth=1 --branch=main --recursive https://github.com/wezterm/wezterm.git "$WEZTERM_DIR"
    print_success "WezTerm cloned successfully!"
  fi

  echo ""
  print_info "Updating WezTerm submodules..."
  cd "$WEZTERM_DIR"
  git submodule update --init --recursive

  echo ""
  print_info "Installing WezTerm dependencies..."
  ./get-deps

  echo ""
  print_info "Building WezTerm (this may take a while)..."
  cargo build --release

  if [ $? -eq 0 ]; then
    print_success "WezTerm built successfully!"
    echo ""

    mkdir -p "$LOCAL_BIN"

    if [ -L "$WEZTERM_LINK" ]; then
      print_warning "Removing existing wezterm symlink..."
      rm "$WEZTERM_LINK"
    elif [ -e "$WEZTERM_LINK" ]; then
      print_warning "Found existing wezterm file (not a symlink). Backing up..."
      mkdir -p "$BACKUP_DIR"
      mv "$WEZTERM_LINK" "$BACKUP_DIR/wezterm"
    fi

    ln -s "$WEZTERM_BINARY" "$WEZTERM_LINK"
    print_success "Created symlink: $WEZTERM_LINK -> $WEZTERM_BINARY"

    echo ""
    read -p "$(echo -e ${YELLOW}Do you want to run WezTerm now? \(y/n\): ${NC})" -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      "$WEZTERM_LINK" start
    fi
  else
    print_error "WezTerm build failed. Please check the errors above."
  fi

  cd "$DOTFILES_DIR"

  echo ""
  print_separator
  print_success "WezTerm setup complete!"
  print_separator
  echo ""
fi
