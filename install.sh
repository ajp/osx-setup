######
# Auto installer of things
######

# Install OhMyZsh
#curl -L http://install.ohmyz.sh | sh	

# Get X-Code Command Line Tools
xcode-select –install

# Install Composer
#curl -sS https://getcomposer.org/installer | php

# Install RVM
curl -sSL https://get.rvm.io | bash -s stable --ruby
gem install bundler

# Install Homebrew
ruby -e “$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)”
brew doctor
brew update

# Run Homebrew Brewfile
tap 'homebrew/bundle'
brew bundle

# Install NPM VM
#curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.25.4/install.sh | bash


# Install Laravel Homestead
#