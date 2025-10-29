# LPAC文件配置指南

## 📍 LPAC文件位置

### 原始文件位置

#### Windows版本
- **位置**: `MiniLPA-main/windows_x86/lpac.exe`
- **大小**: 约0.59 MB
- **用途**: Windows开发/测试环境

#### Linux版本获取方式

如果你有 `MiniLPA-Linux-x86_64` 目录（MiniLPA的Linux发布包），可以使用以下方式：

**方式1: 从MiniLPA-Linux-x86_64包中提取（推荐）** ⭐

LPAC被打包在JAR文件的资源中，可以提取：

```powershell
# 在deploy目录运行
cd deploy
.\extract-lpac.ps1
```

这个脚本会：
1. 从 `MiniLPA-Linux-x86_64/lib/app/MiniLPA-all.jar` 中提取 `linux_x86.zip`
2. 解压zip文件找到 `lpac` 可执行文件
3. 复制到 `deploy/lpac/linux-x86_64/lpac`
4. 构建脚本会自动包含此文件到部署包中

**方式2: 从MiniLPA Releases下载**
   - 访问: https://github.com/EsimMoe/MiniLPA/releases/latest
   - 下载对应平台的LPAC压缩包
   - 通常包含在完整发布包中

**方式3: 从构建产物获取**
   ```powershell
   # 在MiniLPA-main项目目录
   cd MiniLPA-main
   .\gradlew.bat setupResources
   # LPAC文件会被下载到 build/lpac/ 目录
   ```

**方式4: 手动编译**
   - LPAC项目: https://github.com/estkme/lpac
   - 需要编译对应平台的可执行文件

## 📦 部署包中的LPAC配置

### 部署目录结构

由于 `local-agent` 的工作目录是 `/www/wwwroot/minilpa`，LPAC文件需要放在：

```
/www/wwwroot/minilpa/
├── app/
│   ├── minilpa-backend.jar
│   └── minilpa-agent.jar
├── linux-x86_64/            # ← LPAC文件目录（与工作目录同级）
│   └── lpac                 # Linux可执行文件
├── frontend/
└── ...
```

**或者**将LPAC放在独立目录，然后创建软链接或符号链接：

```bash
# 方式1: 直接放在工作目录下
mkdir -p /www/wwwroot/minilpa/linux-x86_64
cp lpac /www/wwwroot/minilpa/linux-x86_64/lpac

# 方式2: 独立目录 + 软链接
mkdir -p /www/wwwroot/minilpa/lpac/linux-x86_64
cp lpac /www/wwwroot/minilpa/lpac/linux-x86_64/lpac
ln -s /www/wwwroot/minilpa/lpac /www/wwwroot/minilpa/lpac-link
# 这样访问 /www/wwwroot/minilpa/lpac-link/linux-x86_64/lpac
```

### 支持的平台目录名

根据 `local-agent` 的 `PlatformUtils.kt`，支持的平台格式：

- `windows-x86_64` / `windows-x86`
- `linux-x86_64` / `linux-x86`
- `macos-x86_64` / `macos-aarch64`

### 代码中的查找逻辑

`local-agent` 会在以下位置查找LPAC：

```kotlin
// 从当前工作目录下的 平台目录 查找
val appDataFolder = getAppDataFolder(false)  // 默认是 "."
val platform = getPlatformInfo()             // 如 "linux-x86_64"
val lpacFolder = File(appDataFolder, platform)
// 最终路径: {WorkingDirectory}/linux-x86_64/lpac (Linux)
// 或: {WorkingDirectory}/windows-x86_64/lpac.exe (Windows)
```

**实际路径**：
- systemd服务WorkingDirectory: `/www/wwwroot/minilpa`
- 平台目录: `linux-x86_64`
- 最终查找: `/www/wwwroot/minilpa/linux-x86_64/lpac`

## 🔧 部署时的配置步骤

### 方式1: 手动上传LPAC文件

1. **准备LPAC文件**
   ```bash
   # 在服务器上创建目录
   mkdir -p /www/wwwroot/minilpa/lpac/linux-x86_64
   
   # 上传LPAC文件
   # 将下载的 lpac 文件上传到该目录
   ```

2. **设置执行权限**
   ```bash
   chmod +x /www/wwwroot/minilpa/lpac/linux-x86_64/lpac
   ```

3. **验证**
   ```bash
   /www/wwwroot/minilpa/lpac/linux-x86_64/lpac version
   ```

### 方式2: 使用安装脚本（推荐）

`install.sh` 脚本会自动查找并设置LPAC权限：

```bash
cd /www/wwwroot/minilpa/config
sudo ./install.sh
```

脚本会检查以下位置：
- `$INSTALL_DIR/lpac/linux-x86_64/lpac`
- 如果存在会自动设置执行权限

### 方式3: 修改代码使用绝对路径

如果LPAC不在默认位置，可以修改 `local-agent` 代码或部署时创建软链接。

## ⚠️ 重要提示

1. **平台匹配**: 确保LPAC文件与服务器架构匹配（x86_64 或 x86）
2. **依赖库**: Linux版本的LPAC可能需要依赖库（如libcurl），确保已安装
3. **执行权限**: 必须设置执行权限 `chmod +x`
4. **路径检查**: 启动local-agent后，检查日志确认LPAC路径是否正确

## 🔍 验证LPAC是否可用

### 在服务器上测试

```bash
# 检查文件是否存在
ls -la /www/wwwroot/minilpa/lpac/linux-x86_64/lpac

# 测试执行
/www/wwwroot/minilpa/lpac/linux-x86_64/lpac version

# 检查依赖
ldd /www/wwwroot/minilpa/lpac/linux-x86_64/lpac
```

### 检查local-agent日志

```bash
# 查看代理日志
sudo journalctl -u minilpa-agent -n 50 | grep -i lpac

# 应该看到类似信息：
# LPACExecutor初始化成功，路径: /www/wwwroot/minilpa/linux-x86_64
```

## 📝 当前状态

### Windows开发环境
- ✅ LPAC文件存在于: `MiniLPA-main/windows_x86/lpac.exe`

### Linux部署环境
- ✅ **如果你有 `MiniLPA-Linux-x86_64` 目录**，可以运行 `deploy/extract-lpac.ps1` 自动提取
- ⚠️ 否则需要手动准备Linux版本的LPAC文件
- 📦 可以：
  1. **从MiniLPA-Linux-x86_64包中提取**（推荐，如果可用）
  2. 从MiniLPA Releases下载
  3. 或从构建产物中提取
  4. 或手动编译

### 部署包
- ⚠️ 当前构建脚本**不会自动包含**LPAC文件（因为跨平台原因）
- 📝 需要在部署文档中明确说明手动配置步骤

## 🔄 建议改进

1. **构建脚本增强**: 可以添加选项指定LPAC平台并自动复制
2. **自动化部署**: 在install.sh中添加LPAC下载功能
3. **文档完善**: 在部署文档中更清晰地说明LPAC配置

