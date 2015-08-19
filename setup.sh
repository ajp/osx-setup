#!/bin/sh

#
# HBased on thoughtbot's excellent laptop script with additional help from
# monfresh, 18F, Matt Stauffer and more.
# 
###########################################################
# Helper functions
#
fancy_echo() {
  local fmt="$1"; shift

  # shellcheck disable=SC2059
  printf "\n$fmt\n" "$@"
}

append_to_file() {
  local file="$1"
  local text="$2"

  if [ "$file" = "$HOME/.zshrc" ]; then
    if [ -w "$HOME/.zshrc.local" ]; then
      file="$HOME/.zshrc.local"
    else
      file="$HOME/.zshrc"
    fi
  fi

  if ! grep -Fqs "$text" "$file"; then
    printf "\n%s\n" "$text" >> "$file"
  fi
}

# shellcheck disable=SC2154
trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT

set -e

if [ ! -d "$HOME/.bin/" ]; then
  mkdir "$HOME/.bin"
fi

if [ ! -f "$HOME/.zshrc" ]; then
  touch "$HOME/.zshrc"
fi

# shellcheck disable=SC2016
append_to_file "$HOME/.zshrc" 'export PATH="$HOME/.bin:$PATH"'

case "$SHELL" in
  */zsh) : ;;
  *)
    fancy_echo "Changing your shell to zsh ..."
      chsh -s "$(which zsh)"
    ;;
esac

brew_install_or_upgrade() {
  if brew_is_installed "$1"; then
    if brew_is_upgradable "$1"; then
      fancy_echo "Upgrading %s ..." "$1"
      brew upgrade "$@"
    else
      fancy_echo "Already using the latest version of %s. Skipping ..." "$1"
    fi
  else
    fancy_echo "Installing %s ..." "$1"
    brew install "$@"
  fi
}

brew_is_installed() {
  brew list -1 | grep -Fqx "$1"
}

brew_is_upgradable() {
  ! brew outdated --quiet "$1" >/dev/null
}

brew_tap_is_installed() {
  brew tap | grep -Fqx "$1"
}

brew_tap() {
  if ! brew_tap_is_installed "$1"; then
    fancy_echo "Tapping $1..."
    brew tap "$1" 2> /dev/null
  fi
}

brew_expand_alias() {
  brew info "$1" 2>/dev/null | head -1 | awk '{gsub(/:/, ""); print $1}'
}

brew_cask_expand_alias() {
  brew cask info "$1" 2>/dev/null | head -1 | awk '{gsub(/:/, ""); print $1}'
}

brew_cask_is_installed() {
  local NAME
  NAME=$(brew_cask_expand_alias "$1")
  brew cask list -1 | grep -Fqx "$NAME"
}

app_is_installed() {
  local app_name
  app_name=$(echo "$1" | cut -d'-' -f1)
  find /Applications -iname "$app_name*" -maxdepth 1 | egrep '.*' > /dev/null
}

brew_cask_install() {
  if app_is_installed "$1" || brew_cask_is_installed "$1"; then
    fancy_echo "$1 is already installed. Skipping..."
  else
    fancy_echo "Installing $1..."
    brew cask install "$@"
  fi
}

brew_launchctl_restart() {
  local name="$(brew_expand_alias "$1")"
  local domain="homebrew.mxcl.$name"
  local plist="$domain.plist"

  fancy_echo "Restarting %s ..." "$1"
  mkdir -p "$HOME/Library/LaunchAgents"
  ln -sfv "/usr/local/opt/$name/$plist" "$HOME/Library/LaunchAgents"

  if launchctl list | grep -Fq "$domain"; then
    launchctl unload "$HOME/Library/LaunchAgents/$plist" >/dev/null
  fi
  launchctl load "$HOME/Library/LaunchAgents/$plist" >/dev/null
}

gem_install_or_update() {
  if gem list "$1" | grep "^$1 ("; then
    fancy_echo "Updating %s ..." "$1"
    gem update "$@"
  else
    fancy_echo "Installing %s ..." "$1"
    gem install "$@"
  fi
}

# End of Helper functions
###########################################################





###########################
# Let's install some things
###########################

# Install Homebrew
if ! command -v brew >/dev/null; then
  fancy_echo "Installing Homebrew ..."
    curl -fsS \
      'https://raw.githubusercontent.com/Homebrew/install/master/install' | ruby

    # shellcheck disable=SC2016
    append_to_file "$HOME/.zshrc" 'export PATH="/usr/local/bin:$PATH"'
else
  fancy_echo "Homebrew already installed. Skipping ..."
fi

fancy_echo "Running Homebrew doctor ..."
brew doctor

fancy_echo "Updating Homebrew formulas ..."
brew update

fancy_echo "Installing Homebrew services ..."
brew_tap 'homebrew/services'

# Install zsh
fancy_echo "Installing Zshell ..."
brew_install_or_upgrade 'zsh'

fancy_echo "Installing OhMyZsh ..."
# Install OhMyZsh
curl -L http://install.ohmyz.sh | sh	

# Install Homebrew Bundle
fancy_echo "Tapping Homebrew Bundle (homebrew/bundle) ..."
brew_tap 'homebrew/bundle'

fancy_echo "Running Brewfile ..."
brew bundle
fancy_echo "Brewfile cleanup ..."
brew cleanup

# Install Casks, if you want a separate Caskfile
#fancy_echo "Installing Casks ..."
#brew cask install $(cat Caskfile|grep -v "#")

# Install RVM and latest stable ruby
fancy_echo "Installing RVM and latest stable ruby"
curl -sSL https://get.rvm.io | bash -s stable --ruby
source ~/.rvm/scripts/rvm
source ~/.zshrc

# Update gems and install basic gems
fancy_echo 'Updating Rubygems...'
gem update --system
gem_install_or_update $(cat Gemfile|grep -v "#")

#Install a bunch of Node.js packages
npm install -g $(cat Nodefile|grep -v "#")

fancy_echo 'Wrap it up ...'
