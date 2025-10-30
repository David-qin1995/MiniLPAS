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

## 关于 LPAC 可执行文件

镜像默认不内置 `lpac`（避免平台差异导致构建失败）。如需实际读卡操作，需要在运行时提供 `lpac`：
- 方式一（推荐）：挂载宿主机的 `lpac` 到容器 `/app/lpac/lpac`
  - 在服务器 `~/minilpa-agent/docker-compose.yml` 增加：
```
volumes:
  - /path/to/lpac:/app/lpac/lpac
```
- 方式二：自制包含 `lpac` 的镜像（在 `deploy/agent.Dockerfile` 的 runtime 段自行 COPY 并赋予执行权限）。

## USB 直通
- Linux 主机可用以下任一方式：
```
# 简单粗暴
privileged: true

# 或者精细映射设备
devices:
  - "/dev/bus/usb:/dev/bus/usb"
# 可选：
# network_mode: host
```

## 验证

- 后端：`/api/devices/status` 应显示 `connected: true` 且 `agentCount >= 1`。
- 前端右上角系统状态：Agents 数大于 0；执行操作时能看到实时进度。

## 常见问题

- `host.docker.internal` 在 Linux 不可用：使用 `network_mode: host` 或填入实际内网 IP。
- WS 不可用：反代需开启 WebSocket 升级（Upgrade/Connection 头）；确认 `MINILPA_SERVER_WS_URL` 可达。
