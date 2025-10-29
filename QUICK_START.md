# 快速启动指南

## ✅ 当前运行状态

- **后端服务**: ✅ 运行在 http://localhost:8080
- **前端服务**: ✅ 运行在 http://localhost:3000  
- **本地代理**: ⏳ 需要启动

## 🚀 启动本地代理服务

```powershell
cd D:\code\MiniLPAS\local-agent
$env:JAVA_HOME="D:\code\MiniLPAS\zulu21.46.19-ca-jdk21.0.9-win_x64"
$env:PATH="D:\code\MiniLPAS\zulu21.46.19-ca-jdk21.0.9-win_x64\bin;$env:PATH"
.\gradlew.bat run
```

代理服务将尝试连接到 `ws://localhost:8080/ws/agent`

## 📝 检查连接状态

1. **检查后端服务**: 访问 http://localhost:8080/api/devices/status
2. **检查前端界面**: 访问 http://localhost:3000
3. **查看代理日志**: 检查代理服务窗口的输出

## ⚠️ 常见问题

### 代理无法连接
- 确保后端服务正在运行
- 检查防火墙设置
- 查看代理服务窗口的错误信息

### 前端显示"未连接"
- 这是正常的，需要先启动本地代理服务
- 代理连接后，前端会自动更新状态

## 💡 下一步

代理连接成功后，前端界面将显示：
- ✅ 连接状态：已连接
- 📱 芯片信息（如果有设备）
- 📋 配置文件列表
- 🔔 通知管理

