# MiniLPA Web 宝塔Linux部署方案

## 🎯 快速部署流程

### Windows开发机操作

1. **一键构建部署包**
```powershell
cd deploy
.\build-all.ps1
```

这将生成：
- `dist/minilpa-backend.jar` - 后端服务
- `dist/minilpa-agent.jar` - 本地代理
- `dist/frontend/` - 前端静态文件
- `dist/config/` - 配置文件
- `minilpa-web-deploy.zip` - 完整部署包

2. **打包上传**
   - 将 `dist` 目录或 `minilpa-web-deploy.zip` 上传到服务器
   - 解压到 `/www/wwwroot/minilpa/`

### Linux服务器操作

#### 方式1: 一键安装（推荐）

```bash
# 1. 将文件上传到服务器后
cd /www/wwwroot/minilpa

# 2. 运行安装脚本
chmod +x config/install.sh  # 如果脚本已上传
sudo ./config/install.sh
```

#### 方式2: 手动安装

参考 `DEPLOY.md` 文档的详细步骤

## 📦 项目结构

```
deploy/
├── build-all.ps1          # Windows构建脚本
├── build-all.sh           # Linux构建脚本
├── install.sh             # 服务器一键安装脚本
├── nginx.conf.example     # Nginx配置示例
├── minilpa-backend.service # 后端systemd服务
├── minilpa-agent.service  # 代理systemd服务
├── application-prod.yml   # 生产环境配置
└── DEPLOY.md              # 详细部署文档
```

## 🔧 关键配置

### 1. Nginx配置要点

- 前端静态文件：`/www/wwwroot/minilpa/frontend`
- API代理：`/api/*` → `http://127.0.0.1:8080/api/*`
- WebSocket代理：`/ws/*` → `ws://127.0.0.1:8080/ws/*`

### 2. systemd服务

- 后端：监听8080端口（仅本地）
- 代理：连接本地8080的WebSocket
- 自动重启：服务异常时自动重启

### 3. 环境变量

可在服务文件中配置：
- `JAVA_HOME`: Java安装路径
- `SPRING_PROFILES_ACTIVE`: 环境（prod/dev）

## ⚡ 宝塔面板配置步骤

### 1. 创建网站
- 网站 -> 添加站点
- 域名：你的域名
- 根目录：`/www/wwwroot/minilpa/frontend`
- PHP版本：纯静态

### 2. 修改Nginx配置
- 网站 -> 设置 -> 配置文件
- 复制 `nginx.conf.example` 内容
- 修改域名后保存

### 3. 配置SSL（推荐）
- 网站 -> 设置 -> SSL
- 使用Let's Encrypt免费证书
- 开启强制HTTPS

### 4. 管理服务（可选）
在宝塔面板 -> 软件商店 -> 系统工具中可以：
- 查看systemd服务状态
- 管理服务启停

## 🚀 快速启动检查清单

- [ ] Java 21已安装
- [ ] PCSC服务已安装并运行
- [ ] 文件已上传到服务器
- [ ] systemd服务已配置并启动
- [ ] Nginx配置已设置
- [ ] 防火墙端口已开放（80/443）
- [ ] LPAC可执行文件已配置权限

## 📝 注意事项

1. **安全**：后端8080端口应仅允许本地访问（通过Nginx代理）
2. **权限**：确保`www`用户有读写日志目录的权限
3. **更新**：更新时先停止服务，替换文件，再启动服务
4. **日志**：定期清理日志文件，避免磁盘空间不足

## 🔍 常见问题

### Q: 服务无法启动？
A: 检查Java路径、JAR文件、日志文件权限

### Q: 前端显示未连接？
A: 检查后端服务状态、WebSocket连接、防火墙规则

### Q: PCSC设备无法访问？
A: 确认pcscd服务运行、用户权限、设备驱动

详细故障排查请参考 `DEPLOY.md`

