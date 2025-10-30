# Nginx配置冲突修复指南

## 问题描述

当在宝塔面板中配置Nginx时，可能出现以下错误：
```
nginx: [emerg] "root" directive is duplicate in /www/server/panel/vhost/nginx/你的域名.conf:45
```

## 原因

宝塔面板在创建网站时会自动生成默认的Nginx配置，包含：
- `root` 指令
- `index` 指令
- 其他基本配置

如果直接完整复制 `nginx.conf.example` 的内容，会导致指令重复。

## 解决方案

### 方案1: 仅添加必要的location块（推荐）

不要替换整个配置文件，只**修改或添加**location块：

1. **网站** -> 你的域名 -> **设置** -> **配置文件**

2. 找到现有的配置，**保留**宝塔自动生成的：
   ```nginx
   server {
       listen 80;
       server_name esim.haoyiseo.com;
       root /www/wwwroot/minilpa/frontend;  # 保留这个
       index index.html;  # 保留这个
       
       # 在这里添加或修改location块
   }
   ```

3. **删除**默认的 `location / {}` 块（如果有）

4. **添加**以下location块：
   ```nginx
   # 前端路由（React Router）
   location / {
       try_files $uri $uri/ /index.html;
   }
   
   # 后端API代理
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
   
   # WebSocket代理
   location /ws {
       proxy_pass http://127.0.0.1:8080;
       proxy_http_version 1.1;
       proxy_set_header Upgrade $http_upgrade;
       proxy_set_header Connection "upgrade";
       proxy_set_header Host $host;
       proxy_read_timeout 86400;
   }
   
   # WebSocket代理（本地代理连接）
   location /ws/agent {
       proxy_pass http://127.0.0.1:8080;
       proxy_http_version 1.1;
       proxy_set_header Upgrade $http_upgrade;
       proxy_set_header Connection "upgrade";
       proxy_set_header Host $host;
       proxy_read_timeout 86400;
   }
   
   # 静态资源缓存
   location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
       expires 1y;
       add_header Cache-Control "public, immutable";
   }
   ```

### 方案2: 创建最小配置文件

如果必须替换整个配置，确保**只包含一次**`root`指令：

```nginx
server {
    listen 80;
    server_name esim.haoyiseo.com;
    
    # 日志（可选）
    access_log /www/wwwlogs/minilpa-access.log;
    error_log /www/wwwlogs/minilpa-error.log;
    
    # 前端静态文件（只写一次）
    root /www/wwwroot/minilpa/frontend;
    index index.html;
    
    # 前端路由（React Router）
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # 后端API代理
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
    
    # WebSocket代理
    location /ws {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 86400;
    }
    
    # WebSocket代理（本地代理连接）
    location /ws/agent {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 86400;
    }
    
    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

## 立即修复步骤

### 步骤1: 查看当前配置

```bash
sudo nano /www/server/panel/vhost/nginx/esim.haoyiseo.com.conf
```

或使用宝塔面板：**网站** -> esim.haoyiseo.com -> **设置** -> **配置文件**

### 步骤2: 查找重复的root指令

搜索 `root` 关键词，应该只有**一行** `root` 指令。

### 步骤3: 删除重复的root指令

删除多余的 `root` 行，保留第一行。

### 步骤4: 测试配置

```bash
sudo nginx -t
```

如果显示 `syntax is ok` 和 `test is successful`，说明配置正确。

### 步骤5: 重载Nginx

```bash
sudo nginx -s reload
```

或在宝塔面板中点击 **保存** 后确认重载。

## 宝塔面板快速修复

1. **网站** -> esim.haoyiseo.com -> **设置** -> **配置文件**
2. 按 `Ctrl+F` 搜索 `root`
3. 删除多余的 `root /www/wwwroot/...` 行（保留第一行）
4. 点击 **保存**
5. 点击 **重载配置**

## 常见重复指令

除了 `root`，还可能重复：
- `index` - 索引文件
- `server_name` - 服务器名
- `listen` - 监听端口

解决方法相同：删除重复的指令，只保留一个。

## 验证配置

修复后，测试：

```bash
# 测试配置语法
sudo nginx -t

# 测试API代理
curl http://esim.haoyiseo.com/api/devices/status

# 查看Nginx错误日志
tail -f /www/wwwlogs/minilpa-error.log
```

