FROM gcr.io/distroless/java21

WORKDIR /app

COPY out/artifacts/aeolus_jar/aeolus.jar /app/app.jar

EXPOSE 3333

CMD ["app.jar"]
