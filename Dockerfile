FROM docker.io/debian:stable-slim AS fetcher
ARG SKIP_FETCH_BINARIES="false"
ENV SKIP_FETCH_BINARIES=$SKIP_FETCH_BINARIES
COPY build/01-fetch_binaries.sh build/functions.sh /tmp/

RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y curl wget && \
    bash -x /tmp/01-fetch_binaries.sh


FROM docker.io/library/alpine:3.20 AS batbelt

ARG PACKAGES="git bash curl wget"
ARG KREWPLUGINS="ns"
ARG SKIP_SHELL_UTILS="false"

ENV PACKAGES=$PACKAGES
ENV KREWPLUGINS=$KREWPLUGINS
ENV SKIP_SHELL_UTILS=$SKIP_SHELL_UTILS
ENV HOME=/
ENV KREW_ROOT=/.krew
# Imposta umask per garantire che i file siano leggibili/eseguibili
ENV UMASK=0002

USER root
COPY build/* /tmp/
RUN set -ex \
    && apk update \
    && apk add bash \
    && apk upgrade \
    && apk cache clean

COPY --from=fetcher /tmp/bindir/* /usr/local/bin/
COPY vimrc /.vimrc
COPY motd /etc/motd
COPY entrypoint.sh /entrypoint.sh
COPY zshrc /.zshrc

WORKDIR /

RUN --mount=type=cache,target=/var/cache/apk \
    umask ${UMASK} && \
    mkdir -p /www/public && chmod -R 777 /www && \
    chmod +x /entrypoint.sh && \
    /tmp/02-install_packages.sh && \
    /tmp/03-install_krew.sh && \
    if [ "${SKIP_SHELL_UTILS}" != "true" ]; then /tmp/99-install_shell_utils.sh; fi && \
    find ${KREW_ROOT} -type d -exec chmod 755 {} \; && \
    find ${KREW_ROOT} -type f -exec chmod 644 {} \; && \
    find ${KREW_ROOT}/bin -type f -exec chmod 755 {} \; && \
    chown -R 1001:0 ${KREW_ROOT} && \
    rm -f /tmp/*.sh

USER 1001
EXPOSE 8080 8081
ENTRYPOINT ["/bin/sh", "-c", "/entrypoint.sh"]