[![Docker Repository on Quay](https://quay.io/repository/koma/batbelt/status "Docker Repository on Quay")](https://quay.io/repository/koma/batbelt)
# README

## Preface
This is a stupid image that I use to test environments.

This image has batman superpowers. (That would be none)

I've stolen the idea from [netshoot](https://github.com/nicolaka/netshoot) and added some more tools.


## Info 
This container runs two processes:
- A web server serving /www/ with python listening on port 8081
- A Web Terminal Emulator listening on port 8080 via [ttyd](https://github.com/tsl0922/ttyd).

## Run in podman
You can run it with:
```shell
podman run -dt --rm  \
  -e PASSWORD=password \
  -e ADMIN=admin \
  -p 8080:8080 \
  -p 8081:8081 \
  -v /adirectorytoshare:/www/public \
  quay.io/koma/batbelt:latest
```

## Run in Openshift base deploy
```shell
git clone https://github.com/thekoma/batbelt
oc apply -f https://raw.githubusercontent.com/thekoma/batbelt/master/deploy/manifest-aio/aio.yaml -n <yournamespace>
```

## Note
This image is **HUGE**. 

It contains **hundred** of tools.

Is not intended to be light is intended to be complete as I work with Openshift and normally containers are rootless, so no package will be added at runtime.

## Screenshots
### Login
![Login](/images/screen01.png)


### Split Screen
![split](/images/screen02.png)
## Installed packages

- [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh)
- [oh-my-tmux](https://github.com/gpakosz/.tmux)
- [ctop](https://github.com/bcicen/ctop)
- calicoctl
- [termshark](https://termshark.io)
- oc
- kubectl
- [k9s](https://github.com/derailed/k9s)
- ansible
- zsh
- yq
- wget
- websocat
- vim 
- util-linux
- ttyd
- tshark
- tmux
- tmate
- tcptraceroute
- tcpdump
- strace
- socat
- scapy
- ripgrep
- py3-setuptools
- py3-pip
- pv
- postgresql-client
- podman-remote
- podman-bash-completion
- podman
- pgcli
- openssl
- nmap-nping
- nmap
- ngrep
- nftables
- netcat-openbsd
- net-tools
- net-snmp-tools
- ncdu
- nagios-plugins
- mtr
- mosh
- mariadb-client
- liboping
- libc6-compat
- jq
- ipvsadm
- iputils
- iptraf-ng
- iptables 
- ipset
- iproute2
- iperf3
- iperf
- ioping
- iftop
- htop
- git
- fzf-zsh-completion
- fzf
- fping
- fio
- file
- ethtool
- drill
- dhcping
- curl
- cri-tools
- coreutils
- conntrack-tools
- ceph-utils
- busybox-extras
- buildah
- bridge-utils
- bird
- bind-tools
- bat
- bash-completion
- bash
- apache2-utils
- zsh-vcs