# MiniLPA Web 宝塔Linux部署指南

## 📋 前置要求

### 1. 系统要求
- Linux系统（Ubuntu 20.04+ / CentOS 7+ / Debian 11+）
- 宝塔面板 7.0+
- Java 21（OpenJDK 21或Oracle JDK 21）
- Nginx（宝塔面板自带）
- PCSC-Lite（智能卡服务）

### 2. 安装Java 21

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install openjdk-21-jdk

# CentOS/RHEL
sudo yum install java-21-openjdk-devel

# 或使用宝塔面板 -> 软件商店 -> 运行环境 -> Java 21
```

验证安装：
```bash
java -version  # 应显示 java version "21.x.x"
```

### 3. 安装PCSC-Lite（必须）

```bash
# Ubuntu/Debian
sudo apt install pcscd pcsc-tools libpcsclite-dev

# CentOS/RHEL
sudo yum install pcsc-lite pcsc-lite-devel

# 启动服务
sudo systemctl enable pcscd
sudo systemctl start pcscd
```

## 🚀 部署步骤

### 步骤1: 构建部署包

在Windows开发机上执行：

```powershell
# 方式1: 使用构建脚本（推荐）
cd deploy
.\build-all.ps1

# 方式2: 手动构建
cd web-backend
.\gradlew.bat bootJar

cd ..\local-agent
.\gradlew.bat build

cd ..\web-frontend
npm install
npm run build
```

构建完成后，`deploy/dist` 目录包含：
- `minilpa-backend.jar` - 后端服务
- `minilpa-agent.jar` - 本地代理
- `frontend/` - 前端静态文件
- `config/` - 配置文件
  - `install.sh` - 一键安装脚本 ⚠️ 重要
  - `update.sh` - 更新脚本
  - `application.yml` - 后端配置
  - `*.service` - systemd服务文件
  - `nginx.conf.example` - Nginx配置示例

### 步骤2: 上传文件到服务器

使用宝塔面板文件管理器或FTP，将 `deploy/dist` 目录内容上传到：
```
/www/wwwroot/minilpa/
```

目录结构应该是：
```
/www/wwwroot/minilpa/
├── app/
│   ├── minilpa-backend.jar
│   └── minilpa-agent.jar
├── frontend/           # 前端静态文件
│   ├── index.html
│   ├── assets/
│   └── ...
├── config/
│   ├── application.yml
│   └── ...
├── logs/               # 日志目录（自动创建）
└── lpac/              # LPAC可执行文件（需要从MiniLPA-main复制）
    └── linux-x86_64/
        └── lpac
```

### 步骤3: 配置LPAC可执行文件 ⚠️ 重要

LPAC（Local Profile Assistant Client）是可执行程序，用于执行eSIM操作。

#### 3.1 获取LPAC文件

**方式1: 从MiniLPA Releases下载（推荐）**
```bash
# 访问 https://github.com/EsimMoe/MiniLPA/releases/latest
# 下载对应平台的LPAC文件
# 通常包含在完整发布包中
```

**方式2: 从MiniLPA-main项目构建**
```powershell
# Windows开发机上
cd MiniLPA-main
.\gradlew.bat setupResources
# LPAC文件会被下载到 build/lpac/ 目录
```

**方式3: 手动编译**
- LPAC源码: https://github.com/estkme/lpac
- 需要编译对应Linux平台的版本

#### 3.2 放置LPAC文件

创建目录并上传LPAC文件：
```bash
# 创建目录
mkdir -p /www/wwwroot/minilpa/lpac/linux-x86_64

# 上传LPAC文件到此目录
# 文件应命名为: lpac (无扩展名)

# 设置执行权限
chmod +x /www/wwwroot/minilpa/lpac/linux-x86_64/lpac
```

#### 3.3 验证LPAC

```bash
# 测试LPAC是否可执行
/www/wwwroot/minilpa/lpac/linux-x86_64/lpac version

# 检查依赖库
ldd /www/wwwroot/minilpa/lpac/linux-x86_64/lpac
```

#### 3.4 目录结构

```
/www/wwwroot/minilpa/
└── lpac/
    └── linux-x86_64/        # 根据服务器架构选择
        └── lpac             # 可执行文件
```

**支持的平台目录**（根据服务器架构选择）：
- `linux-x86_64` - 64位Linux（推荐）
- `linux-x86` - 32位Linux
- `windows-x86_64` - 64位Windows
- `windows-x86` - 32位Windows

**注意**: 
- `local-agent` 会根据运行时的平台自动查找对应目录下的LPAC文件
- 查找路径: `当前工作目录/平台目录/lpac`（如 `./linux-x86_64/lpac`）
- systemd服务配置的WorkingDirectory是 `/www/wwwroot/minilpa`
- 因此LPAC应该放在: `/www/wwwroot/minilpa/linux-x86_64/lpac`
- 或者创建软链接: `ln -s /www/wwwroot/minilpa/lpac /www/wwwroot/minilpa`

### 步骤4: 创建systemd服务

#### 4.1 复制服务文件
```bash
sudo cp /www/wwwroot/minilpa/config/minilpa-backend.service /etc/systemd/system/
sudo cp /www/wwwroot/minilpa/config/minilpa-agent.service /etc/systemd/system/
```

#### 4.2 修改服务文件中的路径
编辑 `/etc/systemd/system/minilpa-backend.service`：
- 确认 `JAVA_HOME` 路径正确（可以用 `which java` 或 `readlink -f $(which java)` 查找）
- 确认文件路径正确

#### 4.3 启动服务
```bash
sudo systemctl daemon-reload
sudo systemctl enable minilpa-backend
sudo systemctl enable minilpa-agent
sudo systemctl start minilpa-backend
sudo systemctl start minilpa-agent
```

#### 4.4 检查服务状态
```bash
sudo systemctl status minilpa-backend
sudo systemctl status minilpa-agent
```

查看日志：
```bash
sudo journalctl -u minilpa-backend -f
sudo journalctl -u minilpa-agent -f
```

### 步骤5: 配置Nginx ⚠️ 重要！

**Nginx是必需的**，否则前端无法访问后端API。

Nginx的作用：
- ✅ 提供前端静态文件服务（React构建的文件）
- ✅ 反向代理后端API：`/api/*` → `http://127.0.0.1:8080/api/*`
- ✅ WebSocket代理：`/ws/*` → `http://127.0.0.1:8080/ws/*`
- ✅ 支持HTTPS（通过宝塔SSL功能）

#### 5.1 在宝塔面板中创建网站
1. 进入 **网站** -> **添加站点**
2. 域名：填写你的域名（如 `minilpa.example.com`）
3. 根目录：`/www/wwwroot/minilpa/frontend`
4. PHP版本：纯静态（无需PHP）
5. 点击 **提交** 创建站点

#### 5.2 配置Nginx反向代理

**方式1: 在宝塔面板中编辑（推荐）**

1. 进入 **网站** -> 找到你的域名 -> **设置** -> **配置文件**
2. **完全替换**配置文件内容为以下配置：

```nginx
server {
    listen 80;
    server_name 你的域名.com;  # 改为你的实际域名
    
    access_log /www/wwwlogs/minilpa-access.log;
    error_log /www/wwwlogs/minilpa-error.log;
    
    root /www/wwwroot/minilpa/frontend;
    index index.html;
    
    # 前端路由（React Router支持）
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
    
    # WebSocket代理（本地代理）
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

3. **重要**：将 `你的域名.com` 替换为你的实际域名
4. 点击 **保存**

**方式2: 使用配置文件模板**

```bash
# 1. 复制模板文件
sudo cp /www/wwwroot/minilpa/config/nginx.conf.example \
        /www/server/panel/vhost/nginx/你的域名.conf

# 2. 编辑配置文件，修改server_name
sudo nano /www/server/panel/vhost/nginx/你的域名.conf
# 找到 "server_name your-domain.com;" 改为你的实际域名

# 3. 测试配置语法
sudo nginx -t

# 4. 如果测试通过，重载Nginx
sudo nginx -s reload
```

#### 5.3 验证Nginx配置

```bash
# 测试配置语法
sudo nginx -t

# 如果显示 "syntax is ok" 和 "test is successful"，说明配置正确

# 查看Nginx状态
sudo systemctl status nginx

# 测试API代理是否工作
curl http://localhost/api/devices/status
# 应该返回JSON数据（而不是404）
```

#### 5.4 常见问题排查

如果访问网站时出现502错误：
1. 检查后端服务是否运行：`sudo systemctl status minilpa-backend`
2. 检查后端是否监听8080端口：`sudo netstat -tlnp | grep 8080`
3. 检查Nginx错误日志：`tail -f /www/wwwlogs/minilpa-error.log`

### 步骤6: 配置防火墙

在宝塔面板：
1. **安全** -> **防火墙**
2. 开放端口：
   - 80 (HTTP)
   - 443 (HTTPS，如使用SSL)

### 步骤7: 配置SSL证书（可选但推荐）

在宝塔面板：
1. 进入网站 -> **设置** -> **SSL**
2. 使用 **Let's Encrypt** 免费证书
3. 开启 **强制HTTPS**

### 步骤8: 验证部署

1. 访问网站：`http://你的域名` 或 `https://你的域名`
2. 检查连接状态（前端应显示"已连接"）
3. 测试功能：
   - 查看芯片信息
   - 查看配置文件列表
   - 下载配置文件

## 🔧 常用命令

### 查看服务状态
```bash
sudo systemctl status minilpa-backend
sudo systemctl status minilpa-agent
```

### 重启服务
```bash
sudo systemctl restart minilpa-backend
sudo systemctl restart minilpa-agent
```

### 查看日志
```bash
# systemd日志
sudo journalctl -u minilpa-backend -n 100
sudo journalctl -u minilpa-agent -n 100

# 应用日志文件
tail -f /www/wwwroot/minilpa/logs/backend.log
```

### 停止服务
```bash
sudo systemctl stop minilpa-backend
sudo systemctl stop minilpa-agent
```

### 更新部署
```bash
# 1. 停止服务
sudo systemctl stop minilpa-backend
sudo systemctl stop minilpa-agent

# 2. 备份旧文件
cp /www/wwwroot/minilpa/app/*.jar /www/wwwroot/minilpa/app/backup/

# 3. 上传新文件（通过宝塔文件管理器）

# 4. 启动服务
sudo systemctl start minilpa-backend
sudo systemctl start minilpa-agent
```

## 📁 目录结构说明

```
/www/wwwroot/minilpa/
├── app/                    # 应用程序目录
│   ├── minilpa-backend.jar # 后端JAR
│   └── minilpa-agent.jar   # 代理JAR
├── frontend/               # 前端静态文件（Nginx根目录）
├── config/                 # 配置文件
│   ├── application.yml     # 后端配置
│   └── ...
├── logs/                   # 日志目录
├── lpac/                   # LPAC可执行文件
│   └── linux-x86_64/
│       └── lpac
└── data/                   # 应用数据（自动创建）
    └── .minilpa/           # 配置和缓存
```

## ⚠️ 注意事项

1. **PCSC服务必须运行**：代理需要访问智能卡
   ```bash
   sudo systemctl status pcscd
   ```

2. **Java版本**：必须是Java 21，不能用Java 8或Java 17

3. **LPAC文件权限**：确保lpac可执行文件有执行权限

4. **防火墙**：确保后端8080端口仅允许本地访问（通过Nginx代理）

5. **SSL证书**：生产环境强烈建议使用HTTPS

6. **日志管理**：定期清理日志文件，避免磁盘空间不足

## 🐛 故障排查

### 服务无法启动
1. 检查Java路径：`which java`
2. 检查JAR文件是否存在
3. 查看systemd日志：`sudo journalctl -u minilpa-backend -n 50`

### 前端无法连接
1. 检查后端服务是否运行：`curl http://localhost:8080/api/devices/status`
2. 检查Nginx配置是否正确
3. 查看浏览器控制台错误

### 代理连接失败
1. 检查后端WebSocket端点：`curl http://localhost:8080/ws/agent`
2. 检查代理日志
3. 确认服务器防火墙允许本地8080端口

### PCSC设备无法访问
1. 检查pcscd服务：`sudo systemctl status pcscd`
2. 检查设备：`pcsc_scan`
3. 确认用户权限（可能需要添加到pcscd组）

## 📞 技术支持

如遇到问题，请检查：
1. 系统日志：`sudo journalctl -xe`
2. 应用日志：`/www/wwwroot/minilpa/logs/`
3. Nginx错误日志：宝塔面板 -> 网站 -> 设置 -> 日志

