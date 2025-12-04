#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Print functions
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

# Main script
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

for config_dir in "$DOTFILES_DIR/config_dots"/*; do
  if [ -d "$config_dir" ]; then
    dir_name=$(basename "$config_dir")
    target_path="$HOME/.config/$dir_name"

    if [ -e "$target_path" ]; then
      backup_path="$HOME/.config/${dir_name}_original_backup"
      echo ""
      print_warning "Found existing $dir_name directory. Backing up to ${dir_name}_original_backup..."
      echo ""

      read -p "$(echo -e ${YELLOW}Do you want to proceed with backing up this folder? \(y/n\): ${NC})" -n 1 -r
      echo ""

      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Skipping $dir_name..."
        continue
      fi

      if [ -e "$backup_path" ]; then
        print_warning "Removing existing backup at $backup_path..."
        rm -rf "$backup_path"
      fi

      mv "$target_path" "$backup_path"
      print_success "Backup complete: $backup_path"
      echo ""
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
# if [ "$EUID" -ne 0 ]; then
#   echo "This script requires root privileges. Please enter your password."
#   exec sudo "$0" "$@"
# fi
#
# echo "Root privileges detected... Proceeding..."
#
# sleep 0.5
#
# echo "Starting full system upgrade..."
# paru -Syu
#
# sleep 0.5
#
# echo "Installing core packages..."
#
# sleep 0.5
#
# paru -S matugen quickshell-git
