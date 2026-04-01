FROM alpine:3.20 AS typst

ARG TYPST_VERSION=0.14.2

RUN wget -q https://github.com/typst/typst/releases/download/v${TYPST_VERSION}/typst-x86_64-unknown-linux-musl.tar.xz \
 && tar -xf typst-x86_64-unknown-linux-musl.tar.xz \
 && mv typst-x86_64-unknown-linux-musl/typst /typst

FROM docker.klnsdr.com/nyx-cli:1.4 as builder

WORKDIR /app

COPY . .

RUN nyx build

FROM gcr.io/distroless/java21

WORKDIR /app

COPY --from=builder /app/build/aeolus-0.15.jar /app/app.jar
COPY --from=typst /typst /usr/local/bin/typst

EXPOSE 3333

CMD ["app.jar"]