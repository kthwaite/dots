# List all homebrew packages explicitly installed by the user
brew-list-installed() {
    brew list --installed-on-request
    brew list --cask -l1
}
