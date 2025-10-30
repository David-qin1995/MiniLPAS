#!/usr/bin/env bash
set -euo pipefail

echo "[entrypoint] Starting pcscd..."
# 以守护进程启动 pcscd，并保持 Unix Socket 在 /run/pcscd
mkdir -p /run/pcscd
pcscd --foreground --auto-exit &
PCSC_PID=$!

echo "[entrypoint] MINILPA_SERVER_WS_URL=${MINILPA_SERVER_WS_URL:-}"
echo "[entrypoint] Starting agent..."
exec java -jar /app/agent.jar

