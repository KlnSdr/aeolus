FROM docker.klnsdr.com/nyx-cli:1.1 as builder

WORKDIR /app

COPY . .

RUN nyx build

FROM gcr.io/distroless/java21

WORKDIR /app

COPY --from=builder /app/build/aeolus-0.12.jar /app/app.jar

EXPOSE 3333

CMD ["app.jar"]
