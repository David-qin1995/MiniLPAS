# Agent 容器化部署（GitHub Actions + 宝塔服务器）

一键流程：推送到 main（或手动触发）→ GitHub Actions 构建并推送镜像到 GHCR → SSH 连接宝塔服务器 → 写入 docker-compose.yml → `docker compose up -d` 部署/更新。

## 同机直连（推荐）
- 默认 WebSocket 地址：`ws://127.0.0.1:8080/ws/agent`
- 容器网络：使用 `network_mode: host`（工作流与示例 compose 已默认如此）
- 如需 USB 直通，可同时启用：
```
privileged: true
# 或者设备映射
devices:
  - "/dev/bus/usb:/dev/bus/usb"
```

## 准备
1) 服务器安装 Docker 与 Docker Compose。
2) GitHub Secrets（若不配置将使用默认 127.0.0.1）：
   - `SSH_HOST`、`SSH_USER`、`SSH_KEY`（必需，用于 SSH 部署）
   - `MINILPA_SERVER_WS_URL`（可选，默认 `ws://127.0.0.1:8080/ws/agent`）

## 使用
- Workflow：`.github/workflows/agent-ci-cd.yml`
- 推送到 main 或手动运行即可部署/更新，部署目录：`/www/wwwroot/minilpa/agent`

## 验证
- 后端：`/api/devices/status` 应 `connected: true` 且 `agentCount >= 1`。
- 前端右上角 Agents > 0，操作可见实时进度。

## 常见问题
- `host.docker.internal`（Linux）不可用：已改为 `127.0.0.1` + host 网络。
- WS 不可用：确认后端 8080 在本机监听、compose 使用 host 网络、或调整地址为实际 IP/域名。
