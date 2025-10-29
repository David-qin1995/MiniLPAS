# 部署包检查清单

在构建部署包后，请确认以下文件都在 `dist/` 目录中：

## ✅ 必需文件

### JAR文件（在dist根目录）
- [x] `minilpa-backend.jar` - 后端服务
- [x] `minilpa-agent.jar` - 本地代理

### 前端文件
- [x] `frontend/` - 目录
  - [x] `index.html`
  - [x] `assets/` - 目录（包含JS/CSS文件）

### 配置文件（在 `dist/config/` 目录）
- [x] `install.sh` - **一键安装脚本（重要！）**
- [x] `update.sh` - 更新脚本
- [x] `application.yml` - 后端配置文件
- [x] `minilpa-backend.service` - 后端systemd服务文件
- [x] `minilpa-agent.service` - 代理systemd服务文件
- [x] `nginx.conf.example` - Nginx配置示例

### LPAC文件（在 `dist/lpac/` 目录）⚠️ 重要
- [ ] `lpac/linux-x86_64/lpac` - **Linux LPAC可执行文件（需手动获取）**
  - 注意：构建脚本**不会自动包含**LPAC文件（跨平台原因）
  - 需要从GitHub Releases下载或从构建产物提取
  - 部署时必须配置，否则local-agent无法工作

## 📋 检查方法

在Windows上：
```powershell
cd deploy
.\build-all.ps1

# 检查文件
Get-ChildItem dist -Recurse | Select-Object FullName
```

在Linux上检查：
```bash
cd /path/to/dist
tree -L 2
# 或
find . -type f
```

## ⚠️ 常见问题

### install.sh 缺失
如果 `dist/config/install.sh` 不存在：
1. 重新运行构建脚本：`.\build-all.ps1`
2. 或手动复制：`Copy-Item deploy\install.sh deploy\dist\config\install.sh`

### 文件权限（Linux）
上传到Linux服务器后，确保安装脚本有执行权限：
```bash
chmod +x /www/wwwroot/minilpa/config/install.sh
```

## 📦 完整的dist目录结构应该是：

```
dist/
├── minilpa-backend.jar
├── minilpa-agent.jar
├── frontend/
│   ├── index.html
│   └── assets/
│       ├── *.js
│       └── *.css
└── config/
    ├── install.sh          ⚠️ 必须
    ├── update.sh
    ├── application.yml
    ├── minilpa-backend.service
    ├── minilpa-agent.service
    └── nginx.conf.example
```

