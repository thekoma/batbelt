FROM quay.io/koma/alpine:latest as batbelt
USER root
RUN apk add --nocache --update \
  ttyd \
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
WORKDIR /
RUN HOME=/ sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 
RUN chgrp -R 0  /.zshrc /.oh-my-zsh && chmod -R g=u /.zshrc /.oh-my-zsh
COPY /entrypoint.sh /
RUN chmod +x /entrypoint.sh
USER 1001
ENTRYPOINT [ "/bin/sh", "-c", "/entrypoint.sh" ]
