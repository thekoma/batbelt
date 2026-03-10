#!/bin/bash

script_dir=$(dirname "$0")
source "$script_dir/functions.sh"


if [ ${INSTALL_SHELL_UTILS} -eq 1 ]; then
  # Install oh-my-zsh
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  # Install spaceship-prompt
  git clone "https://github.com/spaceship-prompt/spaceship-prompt.git" "${HOME}/.oh-my-zsh/custom/themes/spaceship-prompt" --depth=1 --single-branch
  ln -s "${HOME}/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme" "${HOME}/.oh-my-zsh/custom/themes/spaceship.zsh-theme"

  # Install zsh-autosuggestions
  git clone "https://github.com/zsh-users/zsh-autosuggestions.git" "${HOME}/.oh-my-zsh/custom//plugins/zsh-autosuggestions" --depth=1 --single-branch

  # Install oh-my-tmux
  cd
  git clone --single-branch --depth=1 https://github.com/gpakosz/.tmux.git ${HOME}/.tmux
  ln -s -f ${HOME}/.tmux/.tmux.conf ${HOME}/.tmux.conf
  cp ${HOME}/.tmux/.tmux.conf.local ${HOME}/.tmux.conf.local
  echo "set-option -g default-shell /bin/zsh" >> ${HOME}/.tmux.conf.local

  # Install vim plugins
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  vim +PlugInstall +qall

  # Correct permissions
  chgrp -R 0  ${HOME}/.zshrc /.oh-my-zsh && chmod -R g=u ${HOME}/.zshrc ${HOME}/.oh-my-zsh  ${HOME}/.vim
  chmod +x /entrypoint.sh
fi