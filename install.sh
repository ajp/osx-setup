######
# Auto installer of things
######

# Install OhMyZsh
#curl -L http://install.ohmyz.sh | sh	

# Get X-Code Command Line Tools - Or install XCode
#xcode-select -–install

# Install Composer
#curl -sS https://getcomposer.org/installer | php

# Install Homebrew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)""
brew doctor
brew update

# Install RVM
curl -sSL https://get.rvm.io | bash -s stable --ruby
source ~/.bash_profile
gem install bundler

############
# Homebrew Casks #
############


# Run Homebrew and Casks
brew tap caskroom/cask
brew tap homebrew/bundle
brew tap homebrew/services

######
# Install Cask
######
brew caskroom/cask/brew-cask

# Node
brew install node

# Git 
brew cask install git
brew cask install github
brew install git-flow
brew install bash-completion

# The cant live withouts 
brew cask install 1password
brew cask install alfred
brew cask install dropbox
brew cask install google-chrome
brew cask install iterm2
brew cask install path-finder
brew cask install textexpander

# PM Communication Tools
brew cask install google-drive
brew cask install google-hangouts
brew cask install harvest
brew cask install slack
brew cask install screenhero
brew cask install skype

# Development Tools
brew cask install codebox
brew cask install kaleidoscope
brew cask install licecap
brew cask install phpstorm
brew cask install screenflow
brew cask install sublime-text
brew cask install sequel-pro
brew cask install transmit
brew cask install tower

# Virtual Machine Things

brew cask install vagrant
brew cask install vagrant-manager
brew cask install virtualbox
brew cask install vmware-fusion

# Web Dev Tools
brew cask install codebox
brew cask install imageoptim
brew cask install paparazzi
brew cask install xscope
brew cask install livereload

# Design Tools
brew cask install adobe-creative-cloud
brew cask install omnigraffle

# Menu bar apps
brew cask install bartender
brew cask install delibar
brew cask install flux
brew cask install hazel

# Personal, Blogging, etc.
brew cask install evernote
brew cask install dayone-cli
brew cask install netnewswire

# Backup and Sync Software
brew cask install arq
brew cask install bittorrent-sync
brew cask install daisydisk
brew cask install doxie

# Media and Downloading
brew cask install 4k-video-downloader
brew cask install airserver
brew cask install airparrot
brew cask install airfoil
brew cask install calibre
brew cask install plex-home-theater
brew cask install plex-media-server
brew cask install send-to-kindle
brew cask install transmission

# Utilities
brew cask install caffeine
brew cask install istat-menus
brew cask install istat-server
brew cask install superduper
brew install wget

# Install NPM VM
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.25.4/install.sh | bash

# Install Laravel Homestead
#