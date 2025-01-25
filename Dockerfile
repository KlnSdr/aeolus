FROM openjdk:21-jdk-slim

WORKDIR /app

COPY out/artifacts/aeolus_jar/aeolus.jar /app/app.jar

EXPOSE 3333

CMD ["java", "-jar", "/app/app.jar"]