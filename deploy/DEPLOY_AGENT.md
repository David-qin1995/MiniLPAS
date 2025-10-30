# Agent 容器化部署（GitHub Actions + 宝塔服务器）

一键流程：推送到 main（或手动触发）→ GitHub Actions 构建并推送镜像到 GHCR → SSH 连接宝塔服务器 → 写入 docker-compose.yml → `docker compose up -d` 部署/更新。

## 准备

1) 服务器安装 Docker 与 Docker Compose。
2) 在 GitHub 仓库设置 Secrets：
   - `SSH_HOST` 服务器 IP/域名
   - `SSH_USER` SSH 用户（有 Docker 权限）
   - `SSH_KEY` 私钥内容（PEM/OpenSSH）
   - `SSH_PORT`（可选）默认 22
   - `MINILPA_SERVER_WS_URL` 例如 `ws://127.0.0.1:8080/ws/agent`

## 使用

- GitHub Actions 流程：`.github/workflows/agent-ci-cd.yml`
- 提交修改到 main 或手动运行 Workflow 即可部署/更新。

## 自定义

- 镜像：默认 `ghcr.io/<OWNER>/minilpa-agent:latest`，可改为自有 Registry。
- USB 直通：在服务器 `~/minilpa-agent/docker-compose.yml` 取消注释：

```
# privileged: true
# devices:
#   - "/dev/bus/usb:/dev/bus/usb"
# network_mode: host
```

## 验证

- 后端 `/api/devices/status` 返回 `connected: true` 且 `agentCount >= 1`。
- 前端右上角 Agents > 0，操作能看到实时进度。

## 常见问题

- `host.docker.internal` 在 Linux 不可用：使用 `network_mode: host` 或填入内网 IP。
- WS 不可用：反向代理需设置 WebSocket 升级头；确认 `MINILPA_SERVER_WS_URL` 可达。
