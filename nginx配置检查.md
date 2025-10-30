# Nginx 配置检查和优化建议

## 📋 当前配置分析

### ✅ 配置正确的地方：

1. **前端静态文件路径** ✓
   ```
   root /www/wwwroot/minilpa/frontend;
   ```
   与部署脚本一致

2. **前端路由配置** ✓
   ```
   location / {
       try_files $uri $uri/ /index.html;
   }
   ```
   支持 React Router

3. **API 代理** ✓
   ```
   location /api/ {
       proxy_pass http://127.0.0.1:8080;
   }
   ```
   正确代理到后端

4. **WebSocket 代理** ✓
   配置了 `/ws` 和 `/ws/agent` 代理

---

## ⚠️ 发现的问题：

### 问题 1：WebSocket Location 顺序问题

**当前配置：**
```nginx
location /ws {
    ...
}

location /ws/agent {
    ...
}
```

**问题：**
- Nginx 会先匹配 `/ws`，导致 `/ws/agent` 请求被 `/ws` 拦截
- 应该将更具体的路径放在前面

**修复方案：**
```nginx
# 更具体的路径放在前面
location /ws/agent {
    proxy_pass http://127.0.0.1:8080;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_read_timeout 86400;
}

location /ws {
    proxy_pass http://127.0.0.1:8080;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_read_timeout 86400;
}
```

---

### 问题 2：WebSocket 路径匹配

**当前配置有两个 `/ws` location：**
- 第一个：`location /ws`
- 第二个：`location /ws/agent`

**优化建议：**
如果只需要 `/ws/agent`，可以删除 `/ws` location，或者使用精确匹配：
```nginx
location = /ws/agent {
    ...
}
```

---

### 问题 3：API 代理缺少尾部斜杠处理

**当前配置：**
```nginx
location /api/ {
    proxy_pass http://127.0.0.1:8080;
}
```

**说明：**
- 有尾部斜杠是**正确的**，这样 `/api/test` 会被转发为 `/api/test`
- 如果没有尾部斜杠，会转发为 `/test`

---

### 问题 4：静态资源缓存配置重复

**当前配置有两个静态资源 location：**

```nginx
# 第一个（正确的）
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff doing2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}

# 第二个（宝塔默认的，可能冲突）
location ~ .*\.(gif|jpg|jpeg|png|bmp|swf)$
{
    expires      30d;
    ...
}

location ~ .*\.(js|css)?$
{
    expires      12h;
    ...
}
```

**问题：**
- 第一个 location 设置了 1年缓存
- 第二个 location 设置了 12h/30d 缓存
- 可能产生冲突

**建议：**
保留第一个配置，删除或注释掉宝塔的默认静态资源配置，或者合并配置。

---

### 问题 5：PHP 配置不需要

**当前配置：**
```nginx
include enable-php-80.conf;
```

**说明：**
- 这是一个纯静态前端 + Java 后端应用
- PHP 配置不需要
- 可以删除或注释，不影响功能

---

## 🔧 推荐的优化配置：

```nginx
server
{
    listen 80;
    server_name esim.haoyiseo.com;
    
    # 前端静态文件
    root /www/wwwroot/minilpa/frontend;
    index index.html;
    
    # CERT-APPLY-CHECK（SSL证书申请相关，保留）
    include /www/server/panel/vhost/홖x/well-known/esim.haoyiseo.com.conf testing;
    
    # 错误页
    error_page 404 /404.html;
    
    # 禁止访问的文件或目录
    location ~ ^/(\.user.ini|\.htaccess|\.git|\.env|\.svn|\.project|LICENSE|README.md)
    {
        return 404;
    }
    
    # SSL 证书验证
    location ~ \.well-known{
        allow all;
    }
    
    if ( $uri ~白 "^/\.well-known/.*\.(php|jsp|py|js|css|lua|ts|go|zip|tar\.gz|rar|7z|sql|bak)$" ) {
        return 403;
    }
    
    # ⭐ 前端路由（React Router）- 必须在最前面
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # ⭐ 后端API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # ⭐ WebSocket代理（本地代理连接）- 更具体的路径在前
    location /ws/agent {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 86400;
    }
    
    # ⭐ WebSocket代理（前端STOMP，如果未来需要）
    location /ws {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 86400;
    }
    
    # ⭐ 静态资源缓存（优化版本）
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # 日志
    access_log  /www/wwwlogs/esim.haoyiseo.com.log;
    error_log  /www/wwwlogs/esim.haoyiseo.com.error.log;
}
```

---

## 📝 关键修改点总结：

1. ✅ **调整 location 顺序**：`/ws/agent` 放在 `/ws` 前面
2. ✅ **删除重复的静态资源配置**：只保留一个
3. ❌ **可选：删除 PHP 配置**：不需要但不影响功能
4. ✅ **确保 `/api/` 有尾部斜杠**：你的配置正确
5. ✅ **添加更多 proxy 头信息**：确保 WebSocket 正常工作

---

## 🧪 测试建议：

部署配置后，测试以下内容：

1. **前端访问**：访问 `http://esim.haoyiseo.com` 应该能看到前端页面
2. **API 测试**：`http://esim.haoyiseo.com/api/test/ws-config` 应该返回 JSON
3. **WebSocket 测试**：检查浏览器控制台，确认 WebSocket 连接成功

---

## ⚠️ 当前可能存在的问题：

根据后端代码，只有 `/ws/agent` 是实际使用的 WebSocket 端点。`/ws` location 目前可能不会被使用（因为 WebSocketConfig.kt 已被注释）。

你可以先测试当前配置，如果 WebSocket 连接正常，就说明配置没问题。如果有问题，按照上面的优化建议修改。

