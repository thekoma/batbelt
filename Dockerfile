FROM docker.io/debian:stable-slim AS fetcher
RUN apt-get update && apt-get install -y \
  curl \
  wget
COPY build/01-fetch_binaries.sh build/functions.sh /tmp/
RUN bash -x /tmp/01-fetch_binaries.sh

FROM docker.io/library/alpine:3.20 AS batbelt
USER root
COPY build/* /tmp/
RUN set -ex \
    && apk update \
    && apk add bash \
    && apk upgrade \
    && apk cache clean

ARG PACKAGES="git bash curl wget"
ARG KREWPLUGINS="ns"
ARG SKIP_SHELL_UTILS=false
ARG SKIP_FETCH_BINARIES=false

ENV PACKAGES=$PACKAGES
ENV KREWPLUGINS=$KREWPLUGINS
ENV SKIP_SHELL_UTILS=$SKIP_SHELL_UTILS
ENV SKIP_FETCH_BINARIES=$SKIP_FETCH_BINARIES
ENV HOME=/

COPY --from=fetcher /tmp/bindir/* /usr/local/bin/
COPY vimrc /.vimrc
COPY /motd /etc/motd
COPY /entrypoint.sh /
COPY /zshrc /.zshrc

WORKDIR /


RUN \
  mkdir -p /www/public; chmod -R 777 /www \
  /tmp/02-install_packages.sh && \
  /tmp/03-install_krew.sh && \
  /tmp/99-install_shell_utils.sh && \
  rm -f /tmp/*.sh

USER 1001
EXPOSE 8080
EXPOSE 8081
ENTRYPOINT [ "/bin/sh", "-c", "/entrypoint.sh" ]