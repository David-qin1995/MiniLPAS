# CI/CD 自动化部署配置指南

本指南将帮助您配置 GitHub Actions，实现代码提交后自动构建并部署到宝塔服务器。

## 📋 前置要求

1. **GitHub 仓库** - 代码已推送到 GitHub
2. **宝塔服务器** - 已安装宝塔面板的 Linux 服务器
3. **SSH 密钥** - 用于连接宝塔服务器的 SSH 密钥

## 🔧 配置步骤

### 步骤 1: 在服务器上生成 SSH 密钥对（如果还没有）

在**本地开发机**上执行：

```bash
ssh-keygen -t rsa -b 4096 -C "github-ci-cd" -f ~/.ssh/baota_github_key
```

这将生成：
- `~/.ssh/baota_github_key` (私钥) - 需要添加到 GitHub Secrets
- `~/.ssh/baota_github_key.pub` (公钥) - 需要添加到服务器

### 步骤 2: 将公钥添加到宝塔服务器

将公钥内容添加到服务器的 `~/.ssh/authorized_keys`：

```bash
# 显示公钥内容
cat ~/.ssh/baota_github_key.pub

# 然后SSH登录到宝塔服务器，执行：
echo "公钥内容" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

或者使用宝塔面板：
- 宝塔面板 → 安全 → SSH管理 → 添加SSH密钥
- 粘贴公钥内容并保存

### 步骤 3: 配置 GitHub Secrets

1. 进入您的 GitHub 仓库
2. 点击 **Settings** → **Secrets and variables** → **Actions**
3. 点击 **New repository secret**，添加以下密钥：

#### 必需 Secrets：

| Secret 名称 | 说明 | 示例值 |
|------------|------|--------|
| `BAOTA_HOST` | 宝塔服务器IP或域名 | `192.168.1.100` 或 `baota.example.com` |
| `BAOTA_USER` | SSH登录用户名 | `root` 或 `www` |
| `BAOTA_SSH_KEY` | SSH私钥（步骤1生成的私钥内容） | `-----BEGIN RSA PRIVATE KEY-----...` |
| `BAOTA_SSH_PORT` | SSH端口（可选，默认22） | `22` |

#### 获取 SSH 私钥内容：

```bash
# 在本地开发机上
cat ~/.ssh/baota_github_key
```

**重要**：复制完整的私钥内容，包括：
```
-----BEGIN RSA PRIVATE KEY-----
...
-----END RSA PRIVATE KEY-----
```

### 步骤 4: 测试 SSH 连接

在本地测试是否能通过SSH连接到服务器：

```bash
ssh -i ~/.ssh/baota_github_key -p 22 root@你的服务器IP
```

如果可以连接，说明配置正确。

### 步骤 5: 确保服务器已配置

确保宝塔服务器上已经：
- ✅ 安装了 Java 21
- ✅ 安装了 PCSC-Lite
- ✅ 已经运行过一次 `install.sh` 脚本（首次部署需要）
- ✅ systemd 服务文件已存在（`/etc/systemd/system/minilpa-backend.service` 等）

## 🚀 使用方法

### 自动触发

推送代码到 `main` 或 `master` 分支，GitHub Actions 会自动：

1. ✅ 检出代码
2. ✅ 构建后端服务（Spring Boot）
3. ✅ 构建本地代理（Kotlin）
4. ✅ 构建前端（React + Vite）
5. ✅ 打包部署文件
6. ✅ 通过SSH上传到服务器
7. ✅ 自动执行部署脚本
8. ✅ 重启服务
9. ✅ 验证部署状态

### 手动触发

1. 进入 GitHub 仓库
2. 点击 **Actions** 标签
3. 选择 **CI/CD - Deploy to Baota** 工作流
4. 点击 **Run workflow** → **Run workflow**

## 📁 部署目录结构

代码会自动部署到服务器：

```
/www/wwwroot/minilpa/
├── app/
│   ├── minilpa-backend.jar  (自动更新)
│   └── minilpa-agent.jar    (自动更新)
├── frontend/                (自动更新)
├── config/                  (配置文件)
├── logs/                    (日志文件)
└── backup/                  (自动备份)
    └── YYYYMMDD_HHMMSS/     (每次部署前备份)
```

## 🔍 查看部署日志

1. **GitHub Actions 日志**：
   - 进入仓库 → Actions → 选择运行记录 → 查看日志

2. **服务器日志**：
   ```bash
   # 查看后端服务日志
   sudo journalctl -u minilpa-backend -f
   
   # 查看代理服务日志
   sudo journalctl -u minilpa-agent -f
   
   # 查看服务状态
   sudo systemctl status minilpa-backend
   sudo systemctl status minilpa-agent
   ```

## ⚠️ 注意事项

1. **首次部署**：需要先在服务器上手动运行 `install.sh` 脚本完成初始配置

2. **SSH 权限**：确保 SSH 用户有 sudo 权限（部署脚本需要 sudo）

3. **防火墙**：确保 GitHub Actions 可以连接到服务器的 SSH 端口（22或自定义端口）

4. **备份**：每次部署前会自动备份旧文件到 `backup/` 目录

5. **服务重启**：部署完成后会自动重启 `minilpa-backend` 和 `minilpa-agent` 服务

## 🐛 故障排查

### 问题1: SSH连接失败

- 检查 `BAOTA_HOST`、`BAOTA_USER`、`BAOTA_SSH_KEY` 是否正确
- 检查服务器防火墙是否开放SSH端口
- 测试本地SSH连接：`ssh -i ~/.ssh/baota_github_key user@host`

### 问题2: 服务启动失败

- 查看服务器日志：`sudo journalctl -u minilpa-backend -n 50`
- 检查Java是否正确安装：`java -version`
- 检查JAR文件权限：`ls -l /www/wwwroot/minilpa/app/*.jar`

### 问题3: 构建失败

- 检查 GitHub Actions 日志中的错误信息
- 确保代码可以正常构建（本地测试）
- 检查依赖是否正确（Gradle、npm）

## 📝 示例：完整配置流程

```bash
# 1. 生成SSH密钥
ssh-keygen -t rsa -b 4096 -C "github-ci-cd" -f ~/.ssh/baota_github_key

# 2. 显示公钥（添加到服务器）
cat ~/.ssh/baota_github_key.pub

# 3. 显示私钥（添加到GitHub Secrets）
cat ~/.ssh/baota_github_key

# 4. 测试连接
ssh -i ~/.ssh/baota_github_key root@你的服务器IP
```

然后在 GitHub 上设置 Secrets，推送代码即可自动部署！

