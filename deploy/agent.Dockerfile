# syntax=docker/dockerfile:1

# ---------- Build stage ----------
FROM eclipse-temurin:21-jdk AS build
WORKDIR /build
COPY local-agent /build/local-agent
WORKDIR /build/local-agent
RUN ./gradlew.bat --version >/dev/null 2>&1 || true
RUN ./gradlew clean build -x test --no-daemon

# ---------- Runtime stage ----------
FROM debian:12-slim
ENV DEBIAN_FRONTEND=noninteractive

# pcsc-lite + CCID 驱动 + 运行时需要的依赖
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    openjdk-21-jre-headless \
    pcscd pcsc-tools libccid usbutils \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 复制 agent 可运行 JAR
COPY --from=build /build/local-agent/build/libs/*-all.jar /app/agent.jar 2>/dev/null || \
    cp /build/local-agent/build/libs/*.jar /app/agent.jar

# 复制 LPAC 可执行文件（Linux x86_64）
COPY deploy/lpac/linux-x86_64/lpac /app/lpac/lpac
RUN chmod +x /app/lpac/lpac

# 启动脚本：先启动 pcscd，再启动 agent
COPY deploy/entrypoint-agent.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 环境变量：后端 WS 地址
ENV MINILPA_SERVER_WS_URL=ws://host.docker.internal:8080/ws/agent

# 需要访问 USB 设备时，请在运行时添加 --device=/dev/bus/usb -v /dev/bus/usb:/dev/bus/usb
ENTRYPOINT ["/entrypoint.sh"]

