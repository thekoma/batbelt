#!/usr/bin/env bash
set -exuo pipefail

get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
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

BINDIR=$(mkdir /tmp/bindir)
mkdir $BINDIR

get_ctop() {
  VERSION=$(get_latest_release bcicen/ctop | sed -e 's/^v//')
  LINK="https://github.com/bcicen/ctop/releases/download/v${VERSION}/ctop-${VERSION}-linux-${ARCH}"
  wget "$LINK" -O $BINDIR/ctop && chmod +x $BINDIR/ctop
}

get_calicoctl() {
  VERSION=$(get_latest_release projectcalico/calicoctl)
  LINK="https://github.com/projectcalico/calicoctl/releases/download/${VERSION}/calicoctl-linux-${ARCH}"
  wget "$LINK" -O $BINDIR/calicoctl && chmod +x $BINDIR/calicoctl
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
      wget "$LINK" -O $BINDIR/termshark.tar.gz && \
      tar -zxvf $BINDIR/termshark.tar.gz && \
      mv "termshark_${VERSION}_linux_${TERM_ARCH}/termshark" $BINDIR/termshark && \
      chmod +x $BINDIR/termshark
      ;;
  esac
}


get_oc() {
  LINK="https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-client-linux.tar.gz"
  wget "$LINK" -O $BINDIR/oc.tar.gz && \
  cd /tmp && \
  tar -zxvvf $BINDIR/oc.tar.gz && \
  chmod +x $BINDIR/oc $BINDIR/kubectl
}

get_ctop
get_calicoctl
get_termshark
get_oc


