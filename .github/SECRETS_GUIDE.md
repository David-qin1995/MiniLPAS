# GitHub Secrets 配置详细指南

本文档详细说明如何填写每个 GitHub Secret，以实现自动化部署。

## 📋 需要配置的 Secrets 列表

| Secret 名称 | 是否必需 | 说明 |
|------------|---------|------|
| `BAOTA_HOST` | ✅ 必需 | 宝塔服务器 IP 或域名 |
| `BAOTA_USER` | ✅ 必需 | SSH 登录用户名 |
| `BAOTA_SSH_KEY` | ✅ 必需 | SSH 私钥内容（完整内容） |
| `BAOTA_SSH_PORT` | ⚪ 可选 | SSH 端口号（默认 22） |

## 🔑 详细配置步骤

### 步骤 1: 生成 SSH 密钥对

在**本地 Windows 电脑**上打开 PowerShell，执行：

```powershell
# 生成 SSH 密钥对
ssh-keygen -t rsa -b 4096 -C "github-ci-cd" -f $HOME\.ssh\baota_github_key

# 查看公钥（用于添加到服务器）
cat $HOME\.ssh\baota_github_key.pub

# 查看私钥（用于添加到 GitHub Secrets）
cat $HOME\.ssh\baota_github_key
```

**输出示例：**

**公钥** (baota_github_key.pub) - **添加到服务器**：
```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC...很长的字符串... github-ci-cd
```

**私钥** (baota_github_key) - **添加到 GitHub Secrets**：
```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...很长的字符串...
...多行内容...
-----END RSA PRIVATE KEY-----
```

### 步骤 2: 将公钥添加到宝塔服务器

#### 方法 1: 通过 SSH 命令行（推荐）

1. **登录到宝塔服务器**：
```bash
ssh root@你的服务器IP
```

2. **添加公钥到 authorized_keys**：
```bash
# 创建 .ssh 目录（如果不存在）
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# 添加公钥（复制刚才 cat 显示的公钥内容）
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... github-ci-cd" >> ~/.ssh/authorized_keys

# 设置权限
chmod 600 ~/.ssh/authorized_keys
```

#### 方法 2: 通过宝塔面板

1. 登录宝塔面板
2. 进入 **安全** → **SSH管理**
3. 点击 **添加SSH密钥**
4. 粘贴公钥内容（从 `baota_github_key.pub` 文件）
5. 保存

#### 方法 3: 使用 SSH-Copy-Id（如果已配置密码登录）

```bash
# 在本地 PowerShell（需要先安装 ssh-copy-id 工具）
ssh-copy-id -i $HOME\.ssh\baota_github_key.pub root@你的服务器IP
```

### 步骤 3: 测试 SSH 连接

在本地 PowerShell 测试连接：

```powershell
# 测试连接
ssh -i $HOME\.ssh\baota_github_key root@你的服务器IP

# 或者如果端口不是 22
ssh -i $HOME\.ssh\baota_github_key -p 端口号 root@你的服务器IP
```

如果能够连接，说明配置成功！

### 步骤 4: 配置 GitHub Secrets

1. **进入 GitHub 仓库**
   - 访问：https://github.com/David-qin1995/MiniLPAS

2. **打开 Secrets 设置**
   - 点击 **Settings**（设置）
   - 左侧菜单选择 **Secrets and variables** → **Actions**
   - 点击 **New repository secret**

3. **依次添加每个 Secret**

#### Secret 1: `BAOTA_HOST`

**Name（名称）**: `BAOTA_HOST`

**Secret（值）**: 
```
192.168.1.100
```
或者如果使用域名：
```
baota.example.com
```

**示例值**：
- IP 地址：`192.168.1.100`
- 域名：`baota.example.com`
- 域名：`server.yourdomain.com`

**如何查找**：
- 在宝塔面板中，查看服务器信息
- 或使用 `ip addr` 命令查看服务器 IP

---

#### Secret 2: `BAOTA_USER`

**Name（名称）**: `BAOTA_USER`

**Secret（值）**: 
```
root
```

**说明**：
- 通常是 `root`（宝塔默认）
- 或者你自定义的 SSH 用户名
- 确保该用户有 sudo 权限（部署脚本需要）

**如何查找**：
```bash
# 在服务器上执行
whoami
```

---

#### Secret 3: `BAOTA_SSH_KEY`

**Name（名称）**: `BAOTA_SSH_KEY`

**Secret（值）**: 
```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0t1u2v3w4x5y6z7
...（完整的多行内容）...
a8b9c0d1e2f3g4h5i6j7k8l9m0n1o2p3q4r5s6t7u8v9w0x1y2z3a4b5c6d7e8f9g0
-----END RSA PRIVATE KEY-----
```

**重要提示**：
- 必须包含 `-----BEGIN RSA PRIVATE KEY-----` 开头
- 必须包含 `-----END RSA PRIVATE KEY-----` 结尾
- 包含所有中间的行
- 不能有额外的空格或换行
- 使用步骤 1 中生成的私钥内容

**获取方法**：
```powershell
# 在 Windows PowerShell 中
cat $HOME\.ssh\baota_github_key
```

**完整示例格式**：
```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...
...（多行）...
-----END RSA PRIVATE KEY-----
```

⚠️ **常见错误**：
- ❌ 只复制了部分内容
- ❌ 缺少开头或结尾标记
- ❌ 复制了公钥而不是私钥
- ❌ 有多余的空格

---

#### Secret 4: `BAOTA_SSH_PORT`（可选）

**Name（名称）**: `BAOTA_SSH_PORT`

**Secret（值）**: 
```
22
```

**说明**：
- 默认 SSH 端口是 `22`
- 如果服务器更改了 SSH 端口，填入实际端口
- 如果不配置此 Secret，默认使用 22 端口

**如何查找**：
- 在宝塔面板 → **安全** 中查看 SSH 端口
- 或查看 `/etc/ssh/sshd_config` 文件中的 `Port` 设置

---

## ✅ 配置验证清单

配置完成后，检查以下项目：

- [ ] ✅ `BAOTA_HOST` - 已填写服务器 IP 或域名
- [ ] ✅ `BAOTA_USER` - 已填写 SSH 用户名（通常是 root）
- [ ] ✅ `BAOTA_SSH_KEY` - 已填写完整私钥（包括 BEGIN 和 END 标记）
- [ ] ✅ `BAOTA_SSH_PORT` - 已填写端口（或不配置，使用默认 22）
- [ ] ✅ 公钥已添加到服务器的 `~/.ssh/authorized_keys`
- [ ] ✅ 本地测试 SSH 连接成功
- [ ] ✅ SSH 用户有 sudo 权限

## 🧪 测试 Secrets 配置

### 方法 1: 手动触发工作流

1. 进入 GitHub 仓库
2. 点击 **Actions** 标签
3. 选择 **CI/CD - Deploy to Baota** 工作流
4. 点击 **Run workflow** → **Run workflow**
5. 查看工作流执行日志

### 方法 2: 推送代码触发

```powershell
# 提交任意更改
git commit --allow-empty -m "测试 CI/CD 部署"
git push origin master
```

### 查看执行结果

1. 进入 **Actions** 页面
2. 点击最新的工作流运行
3. 查看每个步骤的日志
4. 如果有错误，会显示具体的错误信息

## 🐛 常见问题排查

### 问题 1: SSH 连接失败

**错误信息**：
```
Error: failed to connect to host
```

**解决方法**：
1. 检查 `BAOTA_HOST` 是否正确
2. 检查 `BAOTA_SSH_PORT` 是否匹配服务器端口
3. 检查服务器防火墙是否允许 SSH 连接
4. 本地测试：`ssh -i 私钥路径 root@服务器IP`

### 问题 2: 权限被拒绝

**错误信息**：
```
Permission denied (publickey)
```

**解决方法**：
1. 确认公钥已添加到服务器的 `~/.ssh/authorized_keys`
2. 检查文件权限：
   ```bash
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   ```
3. 确认私钥内容完整（包括 BEGIN 和 END 标记）

### 问题 3: sudo 权限不足

**错误信息**：
```
sudo: a password is required
```

**解决方法**：
```bash
# 在服务器上配置无需密码的 sudo（仅用于 CI/CD）
echo "你的用户名 ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/github-ci
```

### 问题 4: 私钥格式错误

**错误信息**：
```
Load key: invalid format
```

**解决方法**：
1. 确认私钥完整（包含所有行）
2. 确认有 `-----BEGIN RSA PRIVATE KEY-----` 开头
3. 确认有 `-----END RSA PRIVATE KEY-----` 结尾
4. 重新生成密钥对

## 📝 快速参考命令

```powershell
# 生成密钥对
ssh-keygen -t rsa -b 4096 -C "github-ci-cd" -f $HOME\.ssh\baota_github_key

# 查看公钥（添加到服务器）
cat $HOME\.ssh\baota_github_key.pub

# 查看私钥（添加到 GitHub Secrets）
cat $HOME\.ssh\baota_github_key

# 测试 SSH 连接
ssh -i $HOME\.ssh\baota_github_key root@你的服务器IP
```

## 💡 安全建议

1. **私钥保密**：私钥不要泄露给任何人
2. **定期更新**：建议定期更新 SSH 密钥
3. **限制权限**：在服务器上只给必要的权限
4. **监控日志**：定期检查部署日志和服务器访问日志

---

完成以上配置后，你的 CI/CD 就可以自动部署了！🚀

