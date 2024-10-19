export ZSH="/.oh-my-zsh"
SPACESHIP_MAVEN_SHOW=false
ZSH_THEME="spaceship"
ZSH_DISABLE_COMPFIX="true"

plugins=(
  zsh-autosuggestions
  git
  themes
  ansible
  colored-man-pages
  colorize
  command-not-found
  common-aliases
  cp
  github
  history
  helm
  history-substring-search
  kubectl
  mosh
  nmap
  oc
  ripgrep
  zsh_reload
  fzf
)
export SPACESHIP_PROMPT_ORDER=(time user dir host git venv pyenv kubectl exec_time line_sep battery vi_mode jobs exit_code char)
export SPACESHIP_HOST_SHOW=always
export SPACESHIP_USER_SHOW=needed
export SPACESHIP_TIME_SHOW=true
export ZSH_DISABLE_COMPFIX=true
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
source $ZSH/oh-my-zsh.sh
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/local/bin/mc mc
cat='bat --paging=never'
unalias grv
cat /etc/motd

