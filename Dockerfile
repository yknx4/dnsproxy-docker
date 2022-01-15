ARG DEBIAN_VERSION=bullseye-slim
ARG UPSTREAM_RELEASE_TAG=v0.40.3

FROM debian:${DEBIAN_VERSION} as download
ARG DEBIAN_VERSION
ARG UPSTREAM_RELEASE_TAG

WORKDIR /tmp

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini

RUN apt update && apt install -y tar curl && \
    mkdir release && \
    curl -L "https://github.com/AdguardTeam/dnsproxy/releases/download/${UPSTREAM_RELEASE_TAG}/dnsproxy-linux-amd64-${UPSTREAM_RELEASE_TAG}.tar.gz" | tar xvz --strip 1 -C ./release

FROM debian:${DEBIAN_VERSION}

ARG DEBIAN_VERSION

LABEL maintainer="@yknx4"

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    ca-certificates \
    bind9-dnsutils \
    libcap2-bin \
 && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 999 dnsproxy && \
    useradd -r -u 999 -g dnsproxy dnsproxy

COPY --from=download /tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

COPY --from=download /tmp/release/linux-amd64/dnsproxy /usr/local/bin/dnsproxy

RUN setcap CAP_NET_BIND_SERVICE+eip /usr/local/bin/dnsproxy

HEALTHCHECK --interval=5s --timeout=3s --start-period=5s CMD nslookup -po=5053 cloudflare.com 127.0.0.1 || exit 1

USER dnsproxy

ENTRYPOINT ["/tini", "--"]
CMD ["/usr/local/bin/dnsproxy", "--config-path=/config/dnsproxy.yml"]