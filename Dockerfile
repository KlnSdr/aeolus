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

FROM --platform=$BUILDPLATFORM node:22-alpine AS frontend
WORKDIR /app/frontend

ARG ELM_VERSION=0.19.1
RUN npm install -g "elm@${ELM_VERSION}" terser

COPY src/aeolus/application/resource/frontend .
RUN elm make src/Main.elm --optimize --output=elm.js
RUN terser elm.js --compress "pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe" --output=elm.opt.js \
 && terser elm.opt.js --mangle --output=elm.js

FROM --platform=$BUILDPLATFORM docker.klnsdr.com/nyx-cli:1.5 AS builder
WORKDIR /app

COPY . .
COPY --from=frontend /app/frontend/index.html /app/frontend/elm.js /app/frontend/favicon.png src/aeolus/application/resource/static/

RUN nyx build

FROM gcr.io/distroless/java21

WORKDIR /app

COPY --from=builder /app/build/*.jar /app/app.jar
COPY --from=typst /typst /usr/local/bin/typst

EXPOSE 3333

CMD ["app.jar"]
