#!/bin/bash

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install spaceship-prompt
git clone "https://github.com/spaceship-prompt/spaceship-prompt.git" "/.oh-my-zsh/custom/themes/spaceship-prompt" --depth=1
ln -s "/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme" "/.oh-my-zsh/custom/themes/spaceship.zsh-theme"

# Install zsh-autosuggestions
git clone "https://github.com/zsh-users/zsh-autosuggestions.git" "/.oh-my-zsh/custom//plugins/zsh-autosuggestions" --depth=1

# Install oh-my-tmux
git clone https://github.com/gpakosz/.tmux.git /.tmux --depth=1
ln -s -f .tmux/.tmux.conf /.tmux.conf
cp .tmux/.tmux.conf.local /.tmux.conf.local
echo "set-option -g default-shell /bin/zsh" >> /.tmux.conf.local

# Install vim plugins
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +PlugInstall +qall

# Correct permissions
chgrp -R 0  /.zshrc /.oh-my-zsh && chmod -R g=u /.zshrc /.oh-my-zsh  /.vim
chmod +x /entrypoint.sh
