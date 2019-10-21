FROM ubuntu:latest

RUN apt-get update && apt-get -y install curl jq git

# download hub release, extract binary to /usr/local/bin
ENV HUB_VERSION=2.12.7
RUN curl -s -L -o /tmp/hub.tgz https://github.com/github/hub/releases/download/v$HUB_VERSION/hub-linux-amd64-$HUB_VERSION.tgz && \
    tar zxf /tmp/hub.tgz -C /tmp && \
    mv /tmp/hub-linux-amd64-$HUB_VERSION/bin/hub /usr/local/bin

COPY entrypoint.sh /entrypoint.sh
RUN chmod +X /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]