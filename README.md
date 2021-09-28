<!-- [![Docker Repository on Quay](https://quay.io/repository/koma/batbelt/status "Docker Repository on Quay")](https://quay.io/repository/koma/batbelt) -->
# Readme

## Badges 
- ![Docker Image Version (tag latest semver)](https://img.shields.io/docker/v/koma85/batbelt/latest) (latest tag and successfully refresh)
- [![Build Status](https://dronegh.koma.link/api/badges/thekoma/batbelt/status.svg)](https://dronegh.koma.link/thekoma/batbelt)  (this is not inndicative od the latest image)
- ![GitHub last commit](https://img.shields.io/github/last-commit/thekoma/batbelt)
- ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/koma85/batbelt/latest)
- [![Docker Repository on Quay](https://quay.io/repository/koma85/batbelt/status "Docker Repository on Quay")](https://quay.io/repository/koma85/batbelt)

## Registries:
- quay.io/koma85/batbelt
- docker.io/koma85/batbelt
- ghcr.io/thekoma/batbelt
- gitlab.com/komanet/batbelt

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
  docker.io/koma85/batbelt:latest
```

## Run in Openshift/K8S basic deploy
```bash
git clone https://github.com/thekoma/batbelt
oc apply -f https://raw.githubusercontent.com/thekoma/batbelt/master/deploy/manifest-aio/aio.yaml -n <yournamespace>
```

## Helm deploy
```bash
# Extract the repository
git clone https://github.com/thekoma/batbelt
# Extract the values.yaml
helm show values batbelt/deploy/helm/batbelt > alfredtakethewheel.yaml
# Edit the values (the ingress part at least unless you are Bruce Waine)

# Install the batbelt
helm upgrade batbelt batbelt/deploy/helm/batbelt  --values alfredtakethewheel.yaml --namespace batbelt
```
### Example values:
```yaml
replicaCount: 1

image:
  repository: docker.io/koma85/batbelt
  pullPolicy: Always
  tag: "latest"

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

serviceAccount:
  create: true
  annotations: {}
  name: "alfred"

podAnnotations: {}

podSecurityContext:
  fsGroup: 0

securityContext:
  capabilities:
    add:
    - ALL
  readOnlyRootFilesystem: false
  runAsNonRoot: false
  runAsUser: 0
  runAsGroup: 0

# Link Service account to privileged SCC
openshift:
  privileged: true

effimeralvolume: true

service:
  service_type: ClusterIP
  terminal:
    port: 8080
    user: admin
    password: iambrucewayne
  webserver:
    port: 8081

routes: "Use ingresses we are in 2021"

ingress:
  enabled: true
  annotations:
    route.openshift.io/termination: "edge"
    # kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: "true"
  hosts:
    - host: "batweb.wayneenterprises.com"
      name: webserver
      path: /
      pathType: Prefix
      backend:
        service:
          name: webserver
    - host: "batbelt.wayneenterprises.com"
      name: terminal
      path: /
      pathType: Prefix
      backend:
        service:
          name: terminal


resources: 
  limits:
    cpu: 500m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

nodeSelector: {}
  # kubernetes.io/hostname: master0

tolerations:
  - key: "batcave"
    operator: "Exists"
    effect: "NoSchedule"
  - key: "batmobile"
    operator: "Exists"
    effect: "NoSchedule"

affinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
    - matchExpressions:
      - key: gotham
        operator: In
        values:
        - night
        - gordon

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

# Updated:
2021-08-31 - v1.1
