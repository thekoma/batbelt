#!/usr/bin/env bash
set -ex pipefail

script_dir=$(dirname "$0")
source "$script_dir/functions.sh"

ARCH=$(uname -m)
case $ARCH in
    x86_64)
        ARCH=amd64
        ;;
    aarch64)
        ARCH=arm64
        ;;
esac

BINDIR="/tmp/bindir"
mkdir $BINDIR

function get_ctop() {
  VERSION=$(get_latest_release bcicen/ctop | sed -e 's/^v//')
  LINK="https://github.com/bcicen/ctop/releases/download/v${VERSION}/ctop-${VERSION}-linux-${ARCH}"
  echo "${LINK}"
  if [ $(validate_url $LINK) -eq 0 ]; then
    color_echo 32 "Downloading ctop for ${ARCH}"
    wget "$LINK" -O $BINDIR/ctop && chmod +x $BINDIR/ctop
  else
    color_echo 31 "no CTOP for ${ARCH}"
  fi
}

function get_calicoctl() {
  VERSION=$(get_latest_release projectcalico/calicoctl)
  LINK="https://github.com/projectcalico/calicoctl/releases/download/${VERSION}/calicoctl-linux-${ARCH}"
  echo "${LINK}"
  if [ $(validate_url $LINK) -eq 0 ]; then
    color_echo 32 "Downloading CALICOCTL for ${ARCH}"
    wget "$LINK" -O $BINDIR/calicoctl && chmod +x $BINDIR/calicoctl
  else
    color_echo 31 "no CALICOCTL for ${ARCH}"
  fi
}

function get_termshark() {
  case "$ARCH" in
    "arm"*)
      echo "echo termshark does not yet support arm" > $BINDIR/termshark && chmod +x $BINDIR/termshark
      ;;
    *)
      VERSION=$(get_latest_release gcla/termshark | sed -e 's/^v//')
      if [ "$ARCH" == "amd64" ]; then
        TERM_ARCH=x64
      else
        TERM_ARCH="$ARCH"
      fi
      LINK="https://github.com/gcla/termshark/releases/download/v${VERSION}/termshark_${VERSION}_linux_${TERM_ARCH}.tar.gz"
      echo "${LINK}"
      if [ $(validate_url $LINK) -eq 0 ]; then
        color_echo 32 "Downloading termshark for ${ARCH}"
        wget "$LINK" -O $BINDIR/termshark.tar.gz && \
        tar -zxvf $BINDIR/termshark.tar.gz && \
        mv "termshark_${VERSION}_linux_${TERM_ARCH}/termshark" $BINDIR/termshark && \
        chmod +x $BINDIR/termshark
      else
        color_echo 31 "no termshark for ${ARCH}"
      fi

      ;;
  esac
}


function get_oc() {
  LINK="https://mirror.openshift.com/pub/openshift-v4/${ARCH}/clients/ocp/stable/openshift-client-linux.tar.gz"
  echo "${LINK}"
  if [ $(validate_url $LINK) -eq 0 ]; then
    color_echo 32 "Downloading oc for ${ARCH}"
    wget "$LINK" -O $BINDIR/oc.tar.gz && \
    cd $BINDIR && \
    tar -zxvvf $BINDIR/oc.tar.gz && \
    chmod +x $BINDIR/oc
    unlink $BINDIR/kubectl
  else
    color_echo 31 "no oc for ${ARCH}"
  fi

}

echo SKIP_FETCH_BINARIES=$SKIP_FETCH_BINARIES
if [ ! $SKIP_FETCH_BINARIES ]; then
  get_ctop
  get_calicoctl
  get_termshark
  get_oc
else
  color_echo 31 "Skipped installign binaries!"
fi
