# 后端/前端 一键容器化部署（GitHub Actions + 宝塔）

- 构建/推送：推送到 main 或手动运行 `Web CI/CD` Workflow
- 部署位置：`/www/wwwroot/minilpa/web`（compose 默认使用 host 网络）
  - 后端监听：127.0.0.1:8080
  - 前端监听：127.0.0.1:8081

## 宝塔 Nginx 反向代理（推荐）
- 将你的站点反代到前端：`http://127.0.0.1:8081`
- 同时转发 API 与 WebSocket 到后端：`http://127.0.0.1:8080`

参考 server 配置片段：
```
location / {
    proxy_pass http://127.0.0.1:8081;
}

location /api/ {
    proxy_pass http://127.0.0.1:8080/api/;
    proxy_http_version 1.1;
}

# WebSocket
location /ws/ {
    proxy_pass http://127.0.0.1:8080/ws/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}
```

## 前端到后端的调用
- 前端默认请求 `/api`（同域），已在 `web-frontend/src/utils/api.ts` 配置为默认 `/api`
- WebSocket 由前端直连 `/ws/client`；Agent 与后端之间为 `/ws/agent`

## 所需 Secrets（与 Agent 相同的 SSH，用于部署）
- `SSH_HOST`、`SSH_USER`、`SSH_KEY`、`SSH_PORT`(可选)

## 验证
- 站点首页打开正常
- `https://你的域名/api/devices/status` 返回 JSON，并在右上角状态显示 Agents 数量
