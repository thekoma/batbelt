# Usa buildkit per il caching ottimizzato
# syntax=docker/dockerfile:1.4

FROM docker.io/debian:stable-slim AS fetcher
ARG SKIP_FETCH_BINARIES="false"
COPY build/01-fetch_binaries.sh build/functions.sh /tmp/
RUN --mount=type=cache,target=/var/cache/apt \
    if [ ! $SKIP_FETCH_BINARIES ]; then \
    apt-get update && apt-get install -y curl wget && \
    bash -x /tmp/01-fetch_binaries.sh; \
    fi

FROM docker.io/library/alpine:3.20 AS batbelt
ARG PACKAGES
ARG KREWPLUGINS
ARG SKIP_SHELL_UTILS="false"

COPY build/* /tmp/
COPY --from=fetcher /tmp/bindir/* /usr/local/bin/
COPY vimrc /.vimrc
COPY motd /etc/motd
COPY entrypoint.sh /
COPY zshrc /.zshrc

# Combina tutti i comandi RUN in uno solo per ridurre i layer
RUN --mount=type=cache,target=/var/cache/apk \
    mkdir -p /www/public && chmod -R 777 /www && \
    /tmp/02-install_packages.sh && \
    /tmp/03-install_krew.sh && \
    if [ ! $SKIP_SHELL_UTILS ]; then /tmp/99-install_shell_utils.sh; fi && \
    rm -f /tmp/*.sh

USER 1001
EXPOSE 8080 8081
ENTRYPOINT [ "/bin/sh", "-c", "/entrypoint.sh" ]