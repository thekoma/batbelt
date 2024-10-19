#!/bin/bash

# Istalling krew

function validate_url(){
  url=$1
  if [[ $(curl -Lo /dev/null --silent -Iw '%{http_code}' "${url}" ) -eq 200 ]]; then
    return true
  else
    return false
  fi
}

color_echo() {
  local color="$1"
  local message="$2"
  echo -e "\033[${color}m$message\033[0m"
}

TMPDIR=$(mktemp -d); cd $TMPDIR
OS="$(uname | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"
KREW="krew-${OS}_${ARCH}"
LINK="https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz"
echo LINK=$LINK
if [ $(validate_url $LINK) ]; then
  curl -fsSLO $LINK
  tar zxvf "${KREW}.tar.gz"
  ./"${KREW}" install krew
  cd; rm -fr $TMPDIR
  export KUBECONFIG=/dev/null
  export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
  if [ $(command -v kubectl) ]; then
    kubectl krew install $KREWPLUGINS
  else
    echo Unable to find kubectl executable. Krew is anyway hot and ready to use.
  fi
else
  color_echo 31 "no krew for ${ARCH}"
fi
