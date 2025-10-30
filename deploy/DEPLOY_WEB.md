# 后端/前端 一键容器化部署（GitHub Actions + 宝塔）

- 触发：推送到 main 或手动运行 `Web CI/CD` Workflow
- 产物：
  - Backend 镜像：`ghcr.io/<OWNER>/minilpa-backend:latest`
  - Frontend 镜像：`ghcr.io/<OWNER>/minilpa-frontend:latest`
- 部署：SSH 到服务器写入 `/www/wwwroot/minilpa/web/docker-compose.yml`，发布到：
  - 后端：`http://<server>:8080`
  - 前端：`http://<server>:8081`

## 所需 Secrets
- 复用 agent 部署同样的：`SSH_HOST`、`SSH_USER`、`SSH_KEY`、`SSH_PORT`(可选)

## 反向代理建议（宝塔 Nginx）
- 将站点反代到 `http://127.0.0.1:8081`（前端）
- WebSocket 需要：
  - `proxy_set_header Upgrade $http_upgrade;`
  - `proxy_set_header Connection "upgrade";`
  - 后端 WS 路径：`/ws/`

## 验证
- `http://<server>:8081` 可打开前端
- `http://<server>:8080/api/devices/status` 返回 `connected` 字段
