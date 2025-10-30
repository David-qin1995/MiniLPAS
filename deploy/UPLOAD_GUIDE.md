# 部署文件上传指南

## ❌ 不需要上传的内容

### MiniLPA-main 文件夹

**重要：`MiniLPA-main/` 文件夹不需要上传到服务器！**

原因：
- `MiniLPA-main/` 是**源代码目录**，包含：
  - Kotlin源代码（`.kt`文件）
  - Gradle构建脚本
  - 开发依赖
  - 开发工具和脚本
- 源代码已经通过 `build-all.ps1` 编译成JAR文件
- 服务器只需要运行**编译后的二进制文件**（JAR），不需要源代码

### 其他不需要上传的文件夹

- ❌ `web-backend/` - 后端源代码（已编译成 `minilpa-backend.jar`）
- ❌ `web-frontend/` - 前端源代码（已构建成静态文件在 `dist/frontend/`）
- ❌ `local-agent/` - 代理源代码（已编译成 `minilpa-agent.jar`）
- ❌ `deploy/` - 部署脚本（`dist`目录已经包含编译后的文件）
- ❌ `.git/` - Git版本控制目录
- ❌ `build/` - 构建临时目录
- ❌ `node_modules/` - Node.js依赖（前端已构建成静态文件）

## ✅ 需要上传的内容

### 只上传 `deploy/dist/` 目录

运行 `.\build-all.ps1` 后，只需上传 `deploy/dist/` 目录的**内容**：

```
deploy/dist/
├── minilpa-backend.jar     ✅ 上传
├── minilpa-agent.jar       ✅ 上传
├── frontend/              ✅ 上传整个目录
│   ├── index.html
│   ├── assets/
│   └── ...
└── config/                ✅ 上传整个目录
    ├── install.sh
    ├── application.yml
    ├── nginx.conf.example
    └── ...
```

### 上传后的服务器目录结构

```
/www/wwwroot/minilpa/
├── minilpa-backend.jar     (从 dist/ 根目录)
├── minilpa-agent.jar       (从 dist/ 根目录)
├── frontend/               (从 dist/frontend/)
├── config/                 (从 dist/config/)
└── ... 其他文件
```

**注意**：上传时应该上传 `dist/` 目录的**内容**，而不是 `dist` 目录本身。

## 📤 上传方法

### 方法1: 使用宝塔面板（推荐）

1. 在本地压缩 `deploy/dist/` 目录内容：
   ```powershell
   cd deploy
   # 进入dist目录，选择所有内容，压缩成zip
   ```

2. 在宝塔面板：
   - **文件** -> 进入 `/www/wwwroot/minilpa/`
   - **上传** -> 上传zip文件
   - **解压** -> 解压到当前目录

### 方法2: 使用FTP工具

1. 连接到服务器
2. 进入 `/www/wwwroot/minilpa/`
3. 上传 `dist/` 目录下的所有文件和文件夹（**不是上传dist目录本身**）

### 方法3: 使用命令行（SCP）

```bash
# 从Windows PowerShell或Linux命令行
scp -r deploy/dist/* root@你的服务器IP:/www/wwwroot/minilpa/
```

## 📦 上传文件清单

上传前检查，确保包含：

### 必需文件
- [x] `minilpa-backend.jar` - 后端服务（约30-40MB）
- [x] `minilpa-agent.jar` - 本地代理（约100-200KB）
- [x] `frontend/` - 前端静态文件目录
- [x] `config/` - 配置文件目录

### 配置文件检查
在 `config/` 目录中应该包含：
- [x] `install.sh` - 安装脚本
- [x] `update.sh` - 更新脚本
- [x] `application.yml` - 后端配置
- [x] `minilpa-backend.service` - 后端服务文件
- [x] `minilpa-agent.service` - 代理服务文件
- [x] `nginx.conf.example` - Nginx配置示例

### 可选文件
- [ ] `lpac/` - LPAC文件目录（可能需要手动添加）
- [ ] `README.txt` - 说明文件

## 🔍 验证上传

上传后，在服务器上检查：

```bash
cd /www/wwwroot/minilpa

# 检查文件是否存在
ls -lh *.jar
ls -la frontend/
ls -la config/

# 检查文件大小
du -sh *
```

应该看到：
- `minilpa-backend.jar` - 约30-40MB
- `minilpa-agent.jar` - 约100-200KB
- `frontend/` - 约几MB（包含index.html和assets）
- `config/` - 约几KB到几MB（配置文件很小）

## ⚠️ 常见错误

### 错误1: 上传了整个项目目录
❌ 错误：上传 `MiniLPAS/` 整个项目目录
✅ 正确：只上传 `deploy/dist/` 的内容

### 错误2: 上传了dist目录本身
❌ 错误：上传后目录是 `/www/wwwroot/minilpa/dist/app/`
✅ 正确：上传后目录是 `/www/wwwroot/minilpa/app/`

### 关于app目录的说明

`app/` 目录的来源：
1. **构建脚本** (`build-all.ps1`) 会自动创建 `dist/app/` 目录并放入JAR文件
2. **安装脚本** (`install.sh`) 也会创建 `app/` 目录（如果不存在）
3. **服务文件** (`*.service`) 期望JAR文件在 `app/` 目录中

所以上传时，JAR文件应该已经在 `dist/app/` 目录中，上传后就是 `/www/wwwroot/minilpa/app/`

如果上传时发现JAR文件在根目录而不是app目录：
- 可以手动创建 `app/` 目录并移动文件
- 或者 `install.sh` 脚本会自动检测并移动（已修复）

### 错误3: 缺少JAR文件
- 检查 `dist/` 目录根目录是否有JAR文件
- 确认构建脚本已成功运行完成

### 错误4: 缺少前端文件
- 检查 `dist/frontend/` 目录是否存在
- 确认前端构建成功（应该有 `index.html`）

## 📝 总结

**只需要上传 `deploy/dist/` 目录的内容！**

不要上传：
- ❌ MiniLPA-main/
- ❌ web-backend/
- ❌ web-frontend/
- ❌ local-agent/
- ❌ 任何源代码目录

只上传构建后的产物：
- ✅ JAR文件（后端和代理）
- ✅ 前端静态文件（frontend/）
- ✅ 配置文件（config/）

