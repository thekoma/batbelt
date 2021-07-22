FROM debian:stable-slim as fetcher
COPY build/fetch_binaries.sh /tmp/fetch_binaries.sh
RUN apt-get update && apt-get install -y \
  curl \
  wget

RUN /tmp/fetch_binaries.sh

FROM quay.io/koma/alpine:latest as batbelt
USER root
RUN set -ex \
    && echo "http://nl.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \
    && echo "http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && echo "http://nl.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
    && apk update \
    && apk upgrade \
    && apk add --no-cache \
    zsh \
    yq \
    wget \
    websocat \
    vim \ 
    util-linux \
    ttyd \
    tshark \
    tmux \
    tmate \
    tcptraceroute \
    tcpdump \
    strace \
    socat \
    scapy \
    ripgrep \
    py3-setuptools \
    py3-pip \
    pv \
    postgresql-client \
    podman-remote \
    podman-bash-completion \
    podman \
    pgcli \
    openssl \
    nmap-nping \
    nmap \
    ngrep \
    nftables \
    netcat-openbsd \
    net-tools \
    net-snmp-tools \
    ncdu \
    nagios-plugins \
    mtr \
    mosh \
    mariadb-client \
    liboping \
    libc6-compat \
    kubectl \
    k9s \
    jq \
    ipvsadm \
    iputils \
    iptraf-ng \
    iptables \ 
    ipset \
    iproute2 \
    iperf3 \
    iperf \
    ioping \
    iftop \
    htop \
    git \
    fzf-zsh-completion \
    fzf \
    fping \
    fio \
    file \
    ethtool \
    drill \
    dhcping \
    curl \
    cri-tools \
    coreutils \
    conntrack-tools \
    ceph-utils \
    busybox-extras \
    buildah \
    bridge-utils \
    bird \
    bind-tools \
    bat \
    bash-completion \
    bash \
    apache2-utils \
    ansible \
    zsh-vcs

COPY --from=fetcher /tmp/ctop /usr/local/bin/ctop

# Installing calicoctl
COPY --from=fetcher /tmp/calicoctl /usr/local/bin/calicoctl

# Installing termshark
COPY --from=fetcher /tmp/termshark /usr/local/bin/termshark

# Installing oc
COPY --from=fetcher /tmp/oc /usr/local/bin/oc

# Installing httpie
RUN pip3 install --upgrade pip httpie && rm -r /root/.cache

ENV HOME=/

WORKDIR /

COPY vimrc /.vimrc

COPY /motd /etc/motd
COPY /entrypoint.sh /

RUN mkdir -p /www/public; chmod -R 777 /www

RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
  git clone "https://github.com/spaceship-prompt/spaceship-prompt.git" "/.oh-my-zsh/custom/themes/spaceship-prompt" --depth=1 && \
  ln -s "/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme" "/.oh-my-zsh/custom/themes/spaceship.zsh-theme" && \
  git clone "https://github.com/zsh-users/zsh-autosuggestions.git" "/.oh-my-zsh/custom//plugins/zsh-autosuggestions" --depth=1 && \
  git clone https://github.com/gpakosz/.tmux.git /.tmux --depth=1 && \
  ln -s -f .tmux/.tmux.conf /.tmux.conf && \
  cp .tmux/.tmux.conf.local /.tmux.conf.local && \
  echo "set-option -g default-shell /bin/zsh" >> /.tmux.conf.local && \
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim && \
  vim +PlugInstall +qall && \
  chgrp -R 0  /.zshrc /.oh-my-zsh && chmod -R g=u /.zshrc /.oh-my-zsh  /.vim && \
  chmod +x /entrypoint.sh

COPY /zshrc /.zshrc

USER 1001
EXPOSE 8080
EXPOSE 8081
ENTRYPOINT [ "/bin/sh", "-c", "/entrypoint.sh" ]