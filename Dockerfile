FROM alpine:3.20 AS typst

ARG TYPST_VERSION=0.14.2
ARG TARGETARCH
RUN set -eux; \
    case "$TARGETARCH" in \
      amd64) TYPST_ARCH=x86_64 ;; \
      arm64) TYPST_ARCH=aarch64 ;; \
      *) echo "Unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    wget -q "https://github.com/typst/typst/releases/download/v${TYPST_VERSION}/typst-${TYPST_ARCH}-unknown-linux-musl.tar.xz" \
 && tar -xf "typst-${TYPST_ARCH}-unknown-linux-musl.tar.xz" \
 && mv "typst-${TYPST_ARCH}-unknown-linux-musl/typst" /typst

FROM --platform=$BUILDPLATFORM docker.klnsdr.com/nyx-cli:1.5 AS builder
WORKDIR /app

COPY . .

RUN nyx build

FROM gcr.io/distroless/java21

WORKDIR /app

COPY --from=builder /app/build/*.jar /app/app.jar
COPY --from=typst /typst /usr/local/bin/typst

EXPOSE 3333

CMD ["app.jar"]