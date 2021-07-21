FROM quay.io/koma/alpine:latest
USER root
RUN apk add --nocache --update \
  vim \
  podman \
  podman-bash-completion \
  podman-remote \
  buildah \
  tshark \
  ceph-utils \
  mtr \
  mariadb-client \
  postgresql-client \
  coreutils \
  nmap \
  netcat-openbsd \
  bind-tools \
  bash-completion \
  zsh \
  net-tools \
  iperf3 \
  iperf \
  curl \
  wget \
  py-pip \
  mosh \
  tmux \
  bash \
  arping \
  nagios-plugins \
  jq \
  yq \
  pv \
  fzf \
  git \
  fping \
  ioping \
  bat \
  fio \
  k9s \
  htop \
  ncdu \
  && \
  apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing \
  tmate \
  pgcli \
  cri-tools \
  kubectl \
  && \
  curl -LO "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-client-linux.tar.gz" && \
  tar -xvzf openshift-client-linux.tar.gz && \
  install -o root -g root -m 0755 oc /usr/local/bin/oc && \
  rm -fr kubectl oc openshift-client-linux.tar.gz README.md && \
  pip3 install --upgrade pip setuptools httpie && \
  rm -r /root/.cache

USER 1001

ENTRYPOINT [ "sleep", "infinity" ]
