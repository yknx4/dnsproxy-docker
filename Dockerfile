ARG DEBIAN_VERSION=bullseye-slim
ARG ASSET_URL
ARG BINARY_NAME

FROM debian:${DEBIAN_VERSION} as download
ARG DEBIAN_VERSION
ARG ASSET_URL
ARG BINARY_NAME

WORKDIR /tmp

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini

RUN apt update && apt install -y tar curl && \
    mkdir release && \
    curl -L "${ASSET_URL}" | tar xvz -C ./release --wildcards --no-anchored "${BINARY_NAME}" --transform='s/.*\///'

FROM debian:${DEBIAN_VERSION}

ARG DEBIAN_VERSION
ARG BINARY_NAME

LABEL maintainer="@yknx4"

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    ca-certificates \
    bind9-dnsutils \
    libcap2-bin \
 && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 999 ${BINARY_NAME} && \
    useradd -r -u 999 -g ${BINARY_NAME} ${BINARY_NAME}

COPY --from=download /tini /tini
RUN chmod +x /tini

COPY --from=download /tmp/release/${BINARY_NAME} /usr/local/bin/${BINARY_NAME}

RUN setcap CAP_NET_BIND_SERVICE+eip /usr/local/bin/${BINARY_NAME}

HEALTHCHECK --interval=5s --timeout=3s --start-period=5s CMD nslookup -po=5053 cloudflare.com 127.0.0.1 || exit 1

USER ${BINARY_NAME}

ENTRYPOINT ["/tini", "--"]
CMD ["/usr/local/bin/${BINARY_NAME}"]