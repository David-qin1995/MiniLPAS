# 故障排除指南

## 代理连接问题

### 症状
前端显示"未连接，请先启动本地代理服务"

### 解决步骤

#### 1. 确认所有服务都在运行

**后端服务**:
```powershell
# 检查是否在运行
Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue

# 重启命令
cd D:\code\MiniLPAS\web-backend
$env:JAVA_HOME="D:\code\MiniLPAS\zulu21.46.19-ca-jdk21.0.9-win_x64"
$env:PATH="D:\code\MiniLPAS\zulu21.46.19-ca-jdk21.0.9-win_x64\bin;$env:PATH"
.\gradlew.bat bootRun
```

**本地代理服务**:
```powershell
cd D:\code\MiniLPAS\local-agent
$env:JAVA_HOME="D:\code\MiniLPAS\zulu21.46.19-ca-jdk21.0.9-win_x64"
$env:PATH="D:\code\MiniLPAS\zulu21.46.19-ca-jdk21.0.9-win_x64\bin;$env:PATH"
.\gradlew.bat run
```

#### 2. 检查连接地址

- **代理连接地址**: `ws://localhost:8080/ws/agent`
- **前端访问地址**: `http://localhost:3000`
- **后端API地址**: `http://localhost:8080`

#### 3. 验证连接

```powershell
# 检查后端状态
Invoke-RestMethod -Uri "http://localhost:8080/api/devices/status" -Method Get

# 应该返回:
# {
#   "success": true,
#   "data": {
#     "connected": true,  # 如果代理已连接
#     "agentCount": 1
#   }
# }
```

#### 4. 常见问题

**问题1**: 代理服务窗口显示连接失败
- **解决**: 确保后端服务已完全启动（等待15-20秒）
- **检查**: 后端服务窗口是否有错误

**问题2**: WebSocket 404错误
- **原因**: 后端配置未加载
- **解决**: 重启后端服务

**问题3**: 代理启动但立即退出
- **检查**: 查看代理服务窗口的错误日志
- **可能原因**: WebSocket连接失败、依赖缺失等

#### 5. 调试技巧

1. **查看代理日志**: 代理服务窗口会显示连接状态
2. **查看后端日志**: 后端服务窗口会显示代理连接事件
3. **测试WebSocket**: 使用浏览器开发者工具测试WebSocket连接

#### 6. 手动测试连接

如果所有服务都在运行但仍未连接，可以：

1. 停止所有服务
2. 按顺序启动：
   - 先启动后端（等待完全启动）
   - 再启动代理（应该能看到连接成功消息）
3. 刷新前端页面

## 项目架构说明

```
浏览器 (前端)
   ↓ HTTP REST API
后端服务 (Spring Boot)
   ↓ WebSocket (/ws/agent)
本地代理 (Kotlin + OkHttp)
   ↓ PCSC
智能卡设备
```

## 联系方式

如果问题持续存在，请提供：
- 代理服务窗口的完整错误日志
- 后端服务窗口的日志
- 浏览器控制台的错误信息

