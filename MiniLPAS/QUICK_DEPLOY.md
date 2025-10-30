# MiniLPA Web 宝塔快速部署指南

## 🚀 三分钟快速部署

### 第一步：构建部署包（Windows）

```powershell
cd deploy
.\build-all.ps1
```

生成的文件在 `deploy/dist/` 目录

#### 🔍 验证部署包（推荐）

构建完成后，运行验证脚本确认文件完整性：

```powershell
.\verify-package.ps1
```

如果显示 "Package verification passed!"，说明部署包完整可用。

也可以运行完整的部署步骤测试：

```powershell
.\test-deployment-steps.ps1
```

这会验证：
- ✅ 所有必需文件是否存在
- ✅ 配置文件格式是否正确
- ✅ 安装脚本是否可用

### 第二步：上传到服务器

**重要：只上传 `deploy/dist/` 目录的内容，不要上传源代码目录！**

#### 不需要上传的内容 ❌
- ❌ `MiniLPA-main/` - 源代码，已编译成JAR，不需要上传
- ❌ `web-backend/`, `web-frontend/`, `local-agent/` - 源代码目录
- ❌ 任何 `.kt`, `.tsx`, `.gradle` 等源代码文件

#### 需要上传的内容 ✅
使用宝塔面板文件管理器或FTP，将 `deploy/dist/` 目录的**内容**上传到：
```
/www/wwwroot/minilpa/
```

上传的内容应该包括：
- ✅ `minilpa-backend.jar`
- ✅ `minilpa-agent.jar`
- ✅ `frontend/` 目录（包含所有前端静态文件）
- ✅ `config/` 目录（包含所有配置文件）

**注意**：上传 `dist/` 目录**内容**，不是 `dist` 目录本身。

详细说明见：`deploy/UPLOAD_GUIDE.md`

### 第三步：配置LPAC文件 ⚠️ 重要

LPAC是可执行程序，**必须手动配置**。

#### 3.1 获取LPAC文件

选择以下方式之一：

1. **从GitHub Releases下载**（推荐）
   - 访问: https://github.com/EsimMoe/MiniLPA/releases/latest
   - 下载对应Linux平台的LPAC文件

2. **从构建产物提取**
   ```powershell
   # Windows开发机上
   cd MiniLPA-main
   .\gradlew.bat setupResources
   # 文件在 build/lpac/linux_x86.zip
   ```

#### 3.2 上传LPAC文件

```bash
# 在服务器上创建目录（注意：与工作目录同级）
mkdir -p /www/wwwroot/minilpa/linux-x86_64

# 上传LPAC文件到此目录，命名为: lpac
# 设置执行权限
chmod +x /www/wwwroot/minilpa/linux-x86_64/lpac
```

目录结构：
```
/www/wwwroot/minilpa/
├── app/
│   ├── minilpa-backend.jar
│   └── minilpa-agent.jar
├── frontend/
├── linux-x86_64/            # ← LPAC文件目录（与工作目录同级）
│   └── lpac                 # 可执行文件
└── config/
```

**注意**: 由于local-agent的工作目录是`/www/wwwroot/minilpa`，LPAC必须放在`/www/wwwroot/minilpa/linux-x86_64/lpac`

详细说明: `deploy/LPAC_SETUP.md`

### 第四步：一键安装（服务器）

上传后，确保文件在正确位置（包括LPAC）。

然后执行：
```bash
cd /www/wwwroot/minilpa/config
chmod +x install.sh
sudo ./install.sh
```

安装脚本会自动：
- 设置LPAC文件权限（如果存在）
- 配置systemd服务
- 启动服务

### 第四步：配置Nginx（重要！）⚠️

**Nginx是必需的**，用于：
- 提供前端静态文件服务
- 反向代理后端API到 `localhost:8080`
- 代理WebSocket连接
- 支持HTTPS访问

#### 4.1 在宝塔面板创建网站

1. **网站** -> **添加站点**
   - 域名：你的域名（如 `minilpa.example.com`）
   - 根目录：`/www/wwwroot/minilpa/frontend`
   - PHP版本：纯静态（无需PHP）
   - 点击**提交**创建站点

#### 4.2 配置Nginx反向代理

⚠️ **重要**：宝塔面板会自动生成 `root`、`index` 等指令，不要完全替换配置文件！

**推荐方法：只添加location块**

1. 进入 **网站** -> 找到你的域名 -> **设置** -> **配置文件**
2. 找到现有的 `server {}` 块
3. **删除**默认的 `location / {}` 块（如果有）
4. **添加**以下location块到 `server {}` 内：

```nginx
# MiniLPA Web Nginx配置
server {
    listen 80;
    server_name 你的域名.com;  # 改为你的实际域名
    
    # 日志
    access_log /www/wwwlogs/minilpa-access.log;
    error_log /www/wwwlogs/minilpa-error.log;
    
    # 前端静态文件
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

**注意**：
- 确保 `root /www/wwwroot/minilpa/frontend;` 只出现一次
- 如果宝塔已自动生成 `root` 指令，删除配置中的重复项
- 点击 **保存**

如果出现 "root directive is duplicate" 错误：
- 搜索配置文件中的 `root`，删除多余的行
- 参考：`deploy/NGINX_FIX.md`

#### 4.3 或完全替换配置文件（备选方案）

如果你必须完全替换配置文件：

```bash
# 1. 备份原配置
sudo cp /www/server/panel/vhost/nginx/你的域名.conf \
        /www/server/panel/vhost/nginx/你的域名.conf.bak

# 2. 复制模板
sudo cp /www/wwwroot/minilpa/config/nginx.conf.example \
        /www/server/panel/vhost/nginx/你的域名.conf

# 3. 编辑配置文件
sudo nano /www/server/panel/vhost/nginx/你的域名.conf
# 修改：将 "your-domain.com" 改为你的实际域名
# 检查：确保只有一个 root 指令（宝塔可能已生成）

# 4. 测试配置语法
sudo nginx -t
# 如果提示 "root directive is duplicate"，删除重复的root行

# 5. 重载Nginx
sudo nginx -s reload
```

#### 4.4 配置SSL证书（可选但强烈推荐）

1. **网站** -> 你的域名 -> **设置** -> **SSL**
2. 选择 **Let's Encrypt** -> **申请**
3. 勾选 **强制HTTPS**
4. 点击 **保存**

**注意**：配置SSL后，需要确保Nginx配置中的端口443也正确配置（宝塔会自动处理）

### 第五步：完成

1. **访问网站**：在浏览器打开 `http://你的域名` 或 `https://你的域名`
2. **检查连接状态**：前端页面应该显示设备连接状态
3. **测试功能**：尝试查看芯片信息、配置文件列表等功能

如果遇到问题，请查看日志：
```bash
# 查看Nginx错误日志
tail -f /www/wwwlogs/minilpa-error.log

# 查看后端日志
sudo journalctl -u minilpa-backend -f

# 查看代理日志
sudo journalctl -u minilpa-agent -f
```

## 📦 部署包结构

上传后的目录结构：
```
/www/wwwroot/minilpa/
├── app/
│   ├── minilpa-backend.jar
│   └── minilpa-agent.jar
├── frontend/        # 前端静态文件
├── config/         # 配置文件
│   ├── install.sh
│   ├── application.yml
│   └── ...
└── logs/           # 日志目录（自动创建）
```

## 🔍 验证部署

### 检查服务
```bash
sudo systemctl status minilpa-backend
sudo systemctl status minilpa-agent
```

### 检查端口
```bash
sudo netstat -tlnp | grep 8080  # 后端应该在监听
curl http://localhost:8080/api/devices/status  # 测试API
```

### 查看日志
```bash
sudo journalctl -u minilpa-backend -f
sudo journalctl -u minilpa-agent -f
```

## 🆙 更新部署

### 方法1: 使用更新脚本

```bash
# 上传新JAR文件到 /www/wwwroot/minilpa/app/
# 命名为 *.jar.new

cd /www/wwwroot/minilpa
sudo ./config/update.sh
```

### 方法2: 手动更新

```bash
sudo systemctl stop minilpa-backend minilpa-agent
# 替换JAR文件
sudo systemctl start minilpa-backend minilpa-agent
```

## ⚠️ 重要提醒

1. **Java 21必须安装** - 不能用Java 8或17
2. **PCSC服务必须运行** - 智能卡访问必需（Linux需要安装pcscd）
3. **LPAC文件** - 需要从MiniLPA-main复制对应平台的lpac到 `/www/wwwroot/minilpa/linux-x86_64/lpac`
4. **Nginx配置** - **必须配置**，否则无法访问前端和后端API
5. **防火墙** - 后端8080端口只需本地访问（通过Nginx代理），不对外开放

## 📞 遇到问题？

查看详细文档：`deploy/DEPLOY.md`
查看故障排查章节获取帮助

