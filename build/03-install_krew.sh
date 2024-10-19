#!/bin/bash

# Istalling krew

script_dir=$(dirname "$0")
source "$script_dir/functions.sh"

TMPDIR=$(mktemp -d); cd $TMPDIR
OS="$(uname | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"

# Install kubectl
LINK="https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"
echo LINK=$LINK
if [ $(validate_url $LINK) -eq 0 ]; then
  color_echo 32 "Downloading kubectl for ${ARCH}"
  curl -fsSLO $LINK
  install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
else
  color_echo 31 "no krew for ${ARCH}"
fi

KREW="krew-${OS}_${ARCH}"
LINK="https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz"
echo LINK=$LINK
if [ $(validate_url $LINK) -eq 0 ]; then
  color_echo 32 "Downloading krew for ${ARCH}"
  curl -fsSLO $LINK
  tar zxvf "${KREW}.tar.gz"
  ./"${KREW}" install krew
  cd; rm -fr $TMPDIR
  export KUBECONFIG=/dev/null
  export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
  if [ -f /usr/local/bin/kubectl ]; then
    kubectl krew install $KREWPLUGINS
  else
    echo Unable to find kubectl executable. Krew is anyway hot and ready to use.
  fi
else
  color_echo 31 "no krew for ${ARCH}"
fi

rm -fr $TMPDIR