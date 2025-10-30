# MiniLPA 服务管理脚本使用指南

## 📋 简介

`manage.sh` 是一个便捷的服务管理脚本，用于管理 MiniLPA 的后端服务和代理服务。

## 🚀 快速开始

### 1. 上传脚本到服务器

如果你通过 CI/CD 部署，脚本会自动包含在部署包中。你也可以手动上传：

```bash
# 上传到服务器
scp deploy/manage.sh user@your-server:/www/wwwroot/minilpa/

# 设置执行权限
ssh user@your-server "chmod +x /www/wwwroot/minilpa/manage.sh"
```

### 2. 创建快捷方式（可选）

```bash
# 创建全局命令（需要 root 权限）
sudo ln -s /www/wwwroot/minilpa/manage.sh /usr/local/bin/minilpa-manage

# 之后就可以在任何位置使用：
minilpa-manage status
```

## 📖 使用方法

### 基本语法

```bash
./manage.sh [命令] [服务]
```

- **命令**: 要执行的操作（status, logs, restart 等）
- **服务**: 服务名称（backend, agent, all）

### 常用命令

#### 1. 查看服务状态

```bash
# 查看所有服务状态（默认）
./manage.sh
./manage.sh status

# 查看特定服务状态
./manage.sh status backend
./manage.sh status agent
```

**输出示例：**
```
=== 服务状态总览 ===

服务: minilpa-backend
状态: 运行中 ✓
开机自启: 是
进程ID: 12345
CPU: 2.3%, 内存: 15.2%, 运行时间: 01:23:45

服务: minilpa-agent
状态: 运行中 ✓
开机自启: 是
进程ID: 12346
CPU: 0.8%, 内存: 8.5%, 运行时间: 01:23:40
```

#### 2. 查看服务日志

```bash
# 查看代理服务日志（默认50行）
./manage.sh logs agent

# 查看后端服务日志（指定行数）
./manage.sh logs backend 100

# 实时查看日志（按 Ctrl+C 退出）
./manage.sh logs backend -f
./manage.sh logs agent --follow
```

#### 3. 重启服务

```bash
# 重启所有服务
./manage.sh restart all
sudo ./manage.sh restart  # 需要 root 权限

# 重启特定服务
sudo ./manage.sh restart backend
sudo ./manage.sh restart agent
```

#### 4. 启动/停止服务

```bash
# 启动所有服务
sudo ./manage.sh start all

# 启动特定服务
sudo ./manage.sh start backend
sudo ./manage.sh start agent

# 停止所有服务
sudo ./manage.sh stop all

# 停止特定服务
sudo ./manage.sh stop backend
sudo ./manage.sh stop agent
```

#### 5. 设置开机自启

```bash
# 设置所有服务开机自启
sudo ./manage.sh enable all

# 设置特定服务开机自启
sudo ./manage.sh enable backend
sudo ./manage.sh enable agent

# 取消开机自启
sudo ./manage.sh disable all
sudo ./manage.sh disable backend
```

#### 6. 健康检查

```bash
# 检查所有服务的健康状态（包括API测试）
./manage.sh health
```

**输出包括：**
- 服务运行状态
- API 连接测试
- 端口占用情况
- 文件完整性检查

#### 7. 查看详细信息

```bash
# 查看所有服务的详细信息
./manage.sh info

# 查看特定服务的详细信息
./manage.sh info backend
./manage.sh info agent
```

#### 8. 检查端口占用

```bash
# 检查相关端口占用情况
./manage.sh ports
```

## 🎯 使用场景示例

### 场景1：服务异常，快速排查

```bash
# 1. 先查看状态
./manage.sh status

# 2. 查看失败服务的日志
./manage.sh logs agent 100

# 3. 如果发现错误，尝试重启
sudo ./manage.sh restart agent

# 4. 再次检查状态
./manage.sh status agent
```

### 场景2：部署后验证

```bash
# 运行完整的健康检查
./manage.sh health

# 如果发现问题，查看详细日志
./manage.sh logs backend -f
```

### 场景3：定期维护

```bash
# 重启所有服务（更新配置后）
sudo ./manage.sh restart all

# 检查服务是否正常
./manage.sh health
```

### 场景4：故障恢复

```bash
# 停止所有服务
sudo ./manage.sh stop all

# 检查日志找出问题
./manage.sh logs backend 200
./manage.sh logs agent 200

# 修复问题后重启
sudo ./manage.sh start backend
sleep 5
sudo ./manage.sh start agent
```

## 📝 注意事项

1. **权限要求**
   - 查看状态、日志：普通用户即可
   - 启动/停止/重启服务：需要 root 权限（使用 `sudo`）

2. **日志查看**
   - 默认显示最近50行日志
   - 可以指定行数：`./manage.sh logs backend 100`
   - 实时日志会持续输出，按 `Ctrl+C` 退出

3. **服务名称**
   - `backend` = minilpa-backend（后端服务）
   - `agent` = minilpa-agent（代理服务）
   - `all` = 所有服务

4. **健康检查**
   - `health` 命令会测试后端 API 连接
   - 如果后端未运行，API 测试会失败
   - 代理服务的连接状态会从日志中提取

## 🔧 故障排查

### 问题1：脚本无法执行

```bash
# 检查权限
ls -l manage.sh

# 设置执行权限
chmod +x manage.sh
```

### 问题2：提示权限不足

```bash
# 对于需要 root 权限的操作，使用 sudo
sudo ./manage.sh restart all
```

### 问题3：服务名称错误

```
错误: 未知的服务名称 'xxx'
```

**解决**: 使用 `backend` 或 `agent`，不是完整的 systemd 服务名。

### 问题4：日志无法查看

**可能原因**:
- systemd 日志服务未运行
- 服务文件路径不正确

**检查**:
```bash
systemctl status systemd-journald
journalctl --list-boots
```

## 📚 命令速查表

| 命令 | 功能 | 需要 sudo | 示例 |
|------|------|-----------|------|
| `status` | 查看状态 | ❌ | `./manage.sh status backend` |
| `logs` | 查看日志 | ❌ | `./manage.sh logs agent -f` |
| `restart` | 重启服务 | ✅ | `sudo ./manage.sh restart all` |
| `start` | 启动服务 | ✅ | `sudo ./manage.sh start backend` |
| `stop` | 停止服务 | ✅ | `sudo ./manage.sh stop agent` |
| `enable` | 开机自启 | ✅ | `sudo ./manage.sh enable all` |
| `disable` | 取消自启 | ✅ | `sudo ./manage.sh disable all` |
| `health` | 健康检查 | ❌ | `./manage.sh health` |
| `info` | 详细信息 | ❌ | `./manage.sh info backend` |
| `ports` | 端口检查 | ❌ | `./manage.sh ports` |

## 💡 提示

1. **快速查看**: 直接运行 `./manage.sh` 或 `./manage.sh status` 查看所有服务状态
2. **实时监控**: 使用 `./manage.sh logs agent -f` 实时查看代理连接日志
3. **一键检查**: 部署后运行 `./manage.sh health` 快速验证所有服务
4. **组合使用**: 可以将命令组合使用，例如：
   ```bash
   ./manage.sh health && sudo ./manage.sh restart all
   ```

