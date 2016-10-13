#!/bin/sh

###########################################################
# Helper functions
# - 18F/laptop
###############
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

  if ! grep -qs "^$text$" "$file"; then
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



app_is_installed() {
  local app_name
  app_name=$(echo "$1" | cut -d'-' -f1)
  find /Applications -iname "$app_name*" -maxdepth 1 | egrep '.*' > /dev/null
}


# Homebrew install or upgrade
# Argument: brew name
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

# 
# Homebrew cask helper functions
# https://github.com/thoughtbot/laptop/wiki#homebrew-cask
#
brew_cask_expand_alias() {
  brew cask info "$1" 2>/dev/null | head -1 | awk '{gsub(/:/, ""); print $1}'
}

brew_cask_is_installed() {
  local NAME=$(brew_cask_expand_alias "$1")
  brew cask list -1 | grep -Fqx "$NAME"
}

brew_cask_install() {
  if ! brew_cask_is_installed "$1"; then
    brew cask install "$@"
  fi
}

brew_cask_install_or_upgrade() {
  if brew_cask_is_installed "$1"; then
    echo "$1 is already installed, brew cask upgrade is not yet implemented"
    brew cask install --force "$@"
  else
    brew_cask_install "$@"
  fi
}

#
# Git Clone or Pull
# https://github.com/thoughtbot/laptop/wiki#git
#
git_clone_or_pull() {
  local REPOSRC=$1
  local LOCALREPO=$2
  local LOCALREPO_VC_DIR=$LOCALREPO/.git
  if [[ ! -d "$LOCALREPO_VC_DIR" ]]; then
    git clone --recursive $REPOSRC $LOCALREPO
  else
    pushd $LOCALREPO
    git pull $REPOSRC && git submodule update --init --recursive
    popd
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

# Remove brew-cask since it is now installed as part of brew tap caskroom/cask.
# See https://github.com/caskroom/homebrew-cask/releases/tag/v0.60.0
if brew_is_installed 'brew-cask'; then
  brew uninstall --force 'brew-cask'
  brew untap caskroom/versions
fi

# Reset Homebrew
brew cleanup
rm -rf /usr/local/Cellar /usr/local/.git && brew cleanup


# Update Homebrew formulas
fancy_echo "Homebrew: Updating formulas ..."
brew update

fancy_echo "Homebrew: Verifying installation..."
if brew doctor; then
  fancy_echo "Homebrew: Your installation is good to go."
else
  fancy_echo "Your Homebrew installation reported some errors or warnings."
  echo "If the warnings are related to Python, you can ignore them."
  echo "Otherwise, review the Homebrew messages to see if any action is needed."
fi


fancy_echo "Homebrew: Tapping services (homebrew/services) ..."
brew_tap 'homebrew/services'

# Install zsh
fancy_echo "zsh: Installing Zshell ..."
brew_install_or_upgrade 'zsh'
brew_install_or_upgrade 'zsh-completions'

# Install OhMyZsh
fancy_echo "zsh: Installing OhMyZsh ..."
curl -L http://install.ohmyz.sh | sh	

fancy_echo "zsh: Adding Tab Completion for Homebrew"
ln -s "$(brew --prefix)/Library/Contributions/brew_zsh_completion.zsh" /usr/local/share/zsh/site-functions

#
# Install Homebrew Formulas from Brewfile
#
if [ -f "Brewfile.local" ]; then
  fancy_echo "Homebrew: Running Brewfile ..."
  . "$HOME/Brewfile.local"
fi

if [ -f "Caskfile.local" ]; then
  fancy_echo "Homebrew Cask: Running Caskfile ..."
  . "$HOME/Caskfile.local"
fi

fancy_echo "Homebrew: Cleanup ..."
brew cleanup

#
# Install RVM and latest stable ruby
#
if ! command -v rbenv >/dev/null; then
  if ! command -v rvm >/dev/null; then
    fancy_echo 'Installing RVM and the latest Ruby...'
    curl -L https://get.rvm.io | bash -s stable --ruby --auto-dotfiles --autolibs=enable
    . ~/.rvm/scripts/rvm
  else
    local_version="$(rvm -v 2> /dev/null | awk '$2 != ""{print $2}')"
    latest_version="$(curl -s https://raw.githubusercontent.com/wayneeseguin/rvm/stable/VERSION)"
    if [ "$local_version" != "$latest_version" ]; then
      fancy_echo 'Upgrading RVM...'
      rvm get stable --auto-dotfiles --autolibs=enable --with-gems="bundler"
    else
      fancy_echo "Already using the latest version of RVM. Skipping..."
    fi
  fi
fi

source ~/.rvm/scripts/rvm
source ~/.zshrc

# Update gems and install basic gems
fancy_echo 'Ruby: Updating gems...'
gem update --system

fancy_echo 'Ruby: Running Gemfile...'
gem_install_or_update $(cat Gemfile.local|grep -v "#")

#
# NODE: Install a bunch of Node.js packages
#
fancy_echo 'Node: Install Node.js'
brew_install_or_upgrade 'node'

if [ -f "Nodefile.local" ]; then
  fancy_echo "Node: Running Nodefile ..."
  . "$HOME/Nodefile.local"
fi

fancy_echo 'Running Local customizations'
if [ -f "$HOME/.laptop.local" ]; then
  . "$HOME/.laptop.local"
fi


fancy_echo 'Wrap it up ...'
