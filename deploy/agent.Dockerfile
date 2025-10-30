# syntax=docker/dockerfile:1

# ---------- Build stage ----------
FROM gradle:8.7-jdk21 AS build
WORKDIR /build/local-agent
COPY local-agent /build/local-agent
RUN gradle clean build -x test --no-daemon

# ---------- Runtime stage ----------
FROM eclipse-temurin:21-jre
ENV DEBIAN_FRONTEND=noninteractive

# pcsc-lite + CCID 驱动 + 运行时需要的依赖（JRE 已由基础镜像提供）
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    pcscd pcsc-tools libccid usbutils \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 复制构建产物并标准化为 agent.jar
COPY --from=build /build/local-agent/build/libs /tmp/libs
RUN set -eux; JAR=$(ls /tmp/libs/*.jar | head -n1); cp "$JAR" /app/agent.jar; rm -rf /tmp/libs

# 启动脚本：先启动 pcscd，再启动 agent
COPY deploy/entrypoint-agent.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 环境变量：后端 WS 地址
ENV MINILPA_SERVER_WS_URL=ws://host.docker.internal:8080/ws/agent

# 如需访问 USB 智能卡读卡器：运行时添加 --device=/dev/bus/usb 或 privileged: true
ENTRYPOINT ["/entrypoint.sh"]

