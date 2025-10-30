# 🔧 Nginx 配置修复方案

## ⚠️ 发现的主要问题：

### **问题：Location 顺序错误**

你的配置中：
```nginx
location /ws {        ← 这个会拦截所有 /ws 开头的请求
    ...
}

location /ws/agent {  ← 这个永远不会被匹配到！
    ...
}
```

**为什么会出问题？**
- Nginx 匹配 location 时，会按顺序查找
- `/ws` 会匹配所有以 `/ws` 开头的请求，包括 `/ws/agent`
- 所以 `/ws/agent` 会被 `/ws` 拦截，无法正确路由

---

## ✅ 修复方案：

### **将更具体的路径放在前面：**

```nginx
# ✅ 正确顺序：
location /ws/agent {  ← 更具体的在前
    proxy_pass http://127.0.0.1:8080;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_read_timeout 86400;
}

location /ws {        ← 更通用的在后
    proxy_pass http://127.0.0.1:8080;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_read_timeout 86400;
}
```

---

## 📝 完整的优化后配置：

```nginx
server {
    listen 80;
    server_name esim.haoyiseo.com;
    
    root /www/wwwroot/minilpa/frontend;
    index index.html;
    
    # CERT-APPLY-CHECK
    include /www/server/panel/vhost/nginx/well-known/esim.haoyiseo.com.conf;
    
    error_page 404 /404.html;
    
    # PHP 配置可以删除（不需要）
    # include enable-php-80.conf;
    
    # REWRITE
    include /www/server/panel/vhost/rewrite/esim.haoyiseo.com.conf;
    
    # 禁止访问的文件
    location ~ ^/(\.user.ini|\.htaccess|\.git|\.env|\.svn|\.project|LICENSE|README.md) {
        return 404;
    }
    
    # SSL 证书验证
    location ~ \.well-known {
        allow all;
    }
    
    if ( $uri ~ "^/\.well-known/.*\.(php|jsp|py|js|css|lua|ts|go|zip|tar\.gz|rar|7z|sql|bak)$" ) {
        return 403;
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
    
    # ⭐ WebSocket代理（代理连接）- 必须放在 /ws 前面
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
    
    # ⭐ WebSocket代理（前端STOMP）
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
    
    # ⭐ 静态资源缓存（只保留这一个）
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # ⭐ 前端路由（React Router）- 放在最后
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    access_log /www/wwwlogs/esim.haoyiseo.com.log;
    error_log /www/wwwlogs/esim.haoyiseo.com.error.log;
}
```

---

## 🔑 关键修改点：

1. ✅ **调整 location 顺序**：`/ws/agent` 放在 `/ws` 前面
2. ✅ **删除重复的静态资源配置**：你原来的配置有两个，删除宝塔默认的那些
3. ❌ **可选删除 PHP 配置**：不需要但不影响

---

## 🧪 测试步骤：

1. **修改配置**（在宝塔面板：网站 -> 设置 -> 配置文件）
2. **测试配置语法**：
   ```bash
   nginx -t
   ```
3. **重载配置**：
   ```bash
   nginx -s reload
   ```
   或在宝塔面板点击"重载配置"
4. **测试访问**：
   - 前端：`http://esim.haoyiseo.com`
   - API：`http://esim.haoyiseo.com/api/test/ws-config`
   - 检查浏览器控制台的 WebSocket 连接

---

## 📊 当前配置状态：

| 配置项 | 状态 | 说明 |
|--------|------|------|
| 前端路径 | ✅ 正确 | `/www/wwwroot/minilpa/frontend` |
| API 代理 | ✅ 正确 | `/api/` 正确代理到 `:8080` |
| WebSocket顺序 | ⚠️ 错误 | 需要调整顺序 |
| 静态资源缓存 | ⚠️ 重复 | 有两个配置，建议只保留一个 |

