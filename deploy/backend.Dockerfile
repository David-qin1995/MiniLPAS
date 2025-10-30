# syntax=docker/dockerfile:1

# ---------- Build stage ----------
FROM gradle:8.7-jdk21 AS build
WORKDIR /build/web-backend
COPY web-backend /build/web-backend
RUN gradle clean build bootJar -x test --no-daemon

# ---------- Runtime stage ----------
FROM eclipse-temurin:21-jre
ENV TZ=Asia/Shanghai
WORKDIR /app
COPY --from=build /build/web-backend/build/libs/*-*.jar /app/app.jar
EXPOSE 8080
ENV JAVA_OPTS=""
ENTRYPOINT ["sh","-c","java $JAVA_OPTS -jar /app/app.jar"]

