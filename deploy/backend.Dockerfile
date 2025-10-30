# syntax=docker/dockerfile:1

# ---------- Build stage ----------
FROM eclipse-temurin:21-jdk AS build
WORKDIR /build
COPY web-backend /build/web-backend
WORKDIR /build/web-backend
RUN ./gradlew.bat --version >/dev/null 2>&1 || true
RUN ./gradlew clean build bootJar -x test --no-daemon

# ---------- Runtime stage ----------
FROM eclipse-temurin:21-jre
ENV TZ=Asia/Shanghai
WORKDIR /app
COPY --from=build /build/web-backend/build/libs/*-*.jar /app/app.jar
EXPOSE 8080
ENV JAVA_OPTS=""
ENTRYPOINT ["sh","-c","java $JAVA_OPTS -jar /app/app.jar"]

