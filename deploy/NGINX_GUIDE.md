# Nginx在MiniLPA Web项目中的作用

## 🎯 Nginx的核心作用

在这个Web项目中，Nginx作为**反向代理服务器**和**静态文件服务器**，承担以下关键职责：

### 1. 反向代理后端API
- **功能**: 将客户端的API请求转发到后端Spring Boot服务
- **路径**: `/api/*` → `http://127.0.0.1:8080/api/*`
- **优势**: 
  - 后端服务只监听本地8080端口，提高安全性
  - 客户端通过标准HTTP/HTTPS端口访问（80/443）
  - 统一入口，方便管理和监控

### 2. 静态文件服务器
- **功能**: 提供前端React构建的静态文件（HTML、JS、CSS等）
- **根目录**: `/www/wwwroot/minilpa/frontend`
- **功能**:
  - 支持React Router的路由（`try_files`）
  - 静态资源缓存优化（CSS、JS等缓存1年）
  - 高效的文件服务

### 3. WebSocket代理
- **功能**: 代理前端和后端的WebSocket连接
- **路径**: 
  - `/ws/*` - 前端WebSocket连接
  - `/ws/agent` - 本地代理的WebSocket连接
- **特点**: 支持长时间连接（24小时超时）

### 4. HTTPS/SSL支持
- **功能**: 通过宝塔面板轻松配置SSL证书
- **优势**: 提供加密的HTTPS访问，保护数据传输安全

## 📐 架构示意

```
┌─────────────────┐
│  用户浏览器      │
│  (访问网站)      │
└────────┬────────┘
         │ HTTP/HTTPS (80/443端口)
         │
┌────────▼──────────────────────────┐
│  Nginx (反向代理 + 静态服务器)    │
│  ├─ /api/* → 转发到后端            │
│  ├─ /ws/* → 转发WebSocket          │
│  └─ /* → 提供前端静态文件          │
└────────┬──────────────────────────┘
         │
    ┌────┴────┐
    │         │
┌───▼───┐ ┌──▼──────────┐
│前端   │ │后端Spring   │
│静态   │ │Boot (8080)  │
│文件   │ └─────────────┘
│目录   │
└───────┘
```

## 🔧 Nginx配置详解

### 配置文件位置
- **开发/参考**: `deploy/nginx.conf.example`
- **部署后**: `/www/server/panel/vhost/nginx/你的域名.conf`（宝塔面板）

### 关键配置项

#### 1. 前端静态文件服务
```nginx
root /www/wwwroot/minilpa/frontend;
index index.html;

location / {
    try_files $uri $uri/ /index.html;  # 支持React Router
}
```

#### 2. 后端API代理
```nginx
location /api/ {
    proxy_pass http://127.0.0.1:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    # ... 其他代理头设置
}
```

#### 3. WebSocket代理
```nginx
location /ws {
    proxy_pass http://127.0.0.1:8080;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_read_timeout 86400;  # 24小时超时
}
```

#### 4. 静态资源缓存
```nginx
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

## 🚀 为什么需要Nginx？

### 不使用Nginx的问题
1. **端口暴露**: 后端8080端口直接暴露在公网，安全风险高
2. **静态文件服务**: Spring Boot不适合高效提供静态文件
3. **HTTPS配置**: 需要在应用层面配置SSL，复杂且性能差
4. **负载均衡**: 无法轻松扩展多个后端实例

### 使用Nginx的优势
1. **安全性**: 后端只监听本地端口，通过Nginx代理访问
2. **性能**: Nginx高效处理静态文件和反向代理
3. **SSL/TLS**: 通过Nginx统一管理HTTPS证书
4. **灵活性**: 可以轻松配置缓存、压缩、负载均衡等
5. **标准实践**: 生产环境的标准部署方案

## 📋 部署时的配置

### 宝塔面板配置步骤

1. **创建网站**
   - 网站 → 添加站点
   - 域名：你的域名
   - 根目录：`/www/wwwroot/minilpa/frontend`
   - PHP版本：纯静态

2. **配置Nginx**
   - 网站 → 设置 → 配置文件
   - 复制 `nginx.conf.example` 的内容
   - 修改 `server_name` 为你的域名
   - 保存

3. **配置SSL（可选但推荐）**
   - 网站 → 设置 → SSL
   - 申请Let's Encrypt证书
   - 开启强制HTTPS

### 手动配置（不使用宝塔）

```bash
# 1. 复制配置文件
sudo cp /www/wwwroot/minilpa/config/nginx.conf.example \
        /etc/nginx/sites-available/minilpa.conf

# 2. 修改配置中的域名和路径
sudo nano /etc/nginx/sites-available/minilpa.conf

# 3. 创建符号链接
sudo ln -s /etc/nginx/sites-available/minilpa.conf \
           /etc/nginx/sites-enabled/minilpa.conf

# 4. 测试配置
sudo nginx -t

# 5. 重载Nginx
sudo nginx -s reload
```

## ✅ 验证Nginx配置

### 检查Nginx状态
```bash
sudo systemctl status nginx
```

### 测试配置语法
```bash
sudo nginx -t
```

### 查看访问日志
```bash
tail -f /www/wwwlogs/minilpa-access.log
```

### 查看错误日志
```bash
tail -f /www/wwwlogs/minilpa-error.log
```

### 测试不同路径
```bash
# 测试静态文件
curl http://localhost/

# 测试API代理
curl http://localhost/api/devices/status

# 测试后端直接访问（应该只能本地访问）
curl http://127.0.0.1:8080/api/devices/status
```

## 🔒 安全建议

1. **防火墙配置**
   - 只开放80和443端口到公网
   - 后端8080端口只允许本地访问（`127.0.0.1`）

2. **HTTPS强制**
   - 配置SSL证书
   - 启用HTTP到HTTPS的重定向

3. **请求限制**
   - 可以配置Nginx限制请求频率
   - 防止DDoS攻击

4. **日志监控**
   - 定期检查访问日志
   - 监控异常请求

## 📝 注意事项

1. **修改配置后必须重载**
   ```bash
   sudo nginx -s reload
   ```

2. **前端路由支持**
   - 必须配置 `try_files` 支持React Router
   - 否则刷新页面会404

3. **WebSocket超时**
   - 默认24小时超时，适合长时间连接

4. **静态资源缓存**
   - 开发时可能需要禁用缓存
   - 生产环境启用缓存提高性能

## 🔗 相关文档

- `deploy/nginx.conf.example` - 完整配置示例
- `QUICK_DEPLOY.md` - 快速部署指南
- `deploy/DEPLOY.md` - 详细部署文档

