FROM docker.io/debian:stable-slim as fetcher
RUN apt-get update && apt-get install -y \
  curl \
  wget
COPY build/01-fetch_binaries.sh build/functions.sh /tmp/
RUN bash -x /tmp/01-fetch_binaries.sh

FROM docker.io/library/alpine:3.20 as batbelt
USER root
COPY build/* /tmp/
RUN set -ex \
    && apk update \
    && apk add bash \
    && apk upgrade \
    && apk cache clean

ENV PACKAGES="\
zsh \
yq \
wget \
websocat \
vim \
util-linux \
ttyd \
tshark \
tmux \
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
fzf-zsh-plugin \
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
zsh-vcs \
httpie \
ansible-core \
"

ENV KREWPLUGINS="\
access-matrix \
ctx \
df-pv \
eksporter \
get-all \
krew \
neat \
ns \
oidc-login \
permissions \
popeye \
rbac-tool \
rbac-view \
resource-capacity \
secretdata \
sniff \
starboard \
stern \
tail \
tree \
view-secret \
who-can \
"

## DEBUG

ENV PACKAGES="wget curl bash git kubectl"
ENV KREWPLUGINS=""
ENV DISABLESHELL_UTILS=true

COPY --from=fetcher /tmp/bindir/* /usr/local/bin/

ENV HOME=/

WORKDIR /

COPY vimrc /.vimrc

COPY /motd /etc/motd
COPY /entrypoint.sh /
COPY /zshrc /.zshrc

RUN mkdir -p /www/public; chmod -R 777 /www

RUN \
  /tmp/02-install_packages.sh && \
  /tmp/03-install_krew.sh && \
  /tmp/99-install_shell_utils.sh && \
  rm -f /tmp/*.sh

USER 1001
EXPOSE 8080
EXPOSE 8081
ENTRYPOINT [ "/bin/sh", "-c", "/entrypoint.sh" ]