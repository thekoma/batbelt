#!/usr/bin/env bash
set -exuo pipefail

get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

function validate_url(){
  if [[ `wget -S --spider $1  2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then return true;else return false; fi
}

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

get_ctop() {
  VERSION=$(get_latest_release bcicen/ctop | sed -e 's/^v//')
  LINK="https://github.com/bcicen/ctop/releases/download/v${VERSION}/ctop-${VERSION}-linux-${ARCH}"
  if [ $(validate_url $LINK) ]; then
    wget "$LINK" -O $BINDIR/ctop && chmod +x $BINDIR/ctop
  else
    echo no CTOP for ${ARCH}
  fi
}

get_calicoctl() {
  VERSION=$(get_latest_release projectcalico/calicoctl)
  LINK="https://github.com/projectcalico/calicoctl/releases/download/${VERSION}/calicoctl-linux-${ARCH}"
  if [ $(validate_url $LINK) ]; then
    wget "$LINK" -O $BINDIR/calicoctl && chmod +x $BINDIR/calicoctl
  else
    echo no calicoctl for ${ARCH}
  fi
}

get_termshark() {
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
      if [ $(validate_url $LINK) ]; then
        wget "$LINK" -O $BINDIR/termshark.tar.gz && \
        tar -zxvf $BINDIR/termshark.tar.gz && \
        mv "termshark_${VERSION}_linux_${TERM_ARCH}/termshark" $BINDIR/termshark && \
        chmod +x $BINDIR/termshark
      else
        echo no termshark for ${ARCH}
      fi

      ;;
  esac
}


get_oc() {
  LINK="https://mirror.openshift.com/pub/openshift-v4/${ARCH}/clients/ocp/stable/openshift-client-linux.tar.gz"
  if [ $(validate_url $LINK) ]; then
    wget "$LINK" -O $BINDIR/oc.tar.gz && \
    cd $BINDIR && \
    tar -zxvvf $BINDIR/oc.tar.gz && \
    chmod +x $BINDIR/oc
    unlink $BINDIR/kubectl
  else
    echo no oc for ${ARCH}
  fi

}

get_ctop
get_calicoctl
get_termshark
get_oc


