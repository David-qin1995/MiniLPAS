# 运行项目指南

## ✅ 当前状态

项目已成功启动！

## 📍 服务地址

- **后端 API**: http://localhost:8080
  - 状态检查: http://localhost:8080/api/devices/status
  - API文档: http://localhost:8080/api/devices

- **前端应用**: http://localhost:3000
  - 在浏览器中打开查看界面

## 🚀 快速启动命令

### 后端服务（已在运行）
```powershell
cd D:\code\MiniLPAS\web-backend
$env:JAVA_HOME="D:\code\MiniLPAS\zulu21.46.19-ca-jdk21.0.9-win_x64"
$env:PATH="D:\code\MiniLPAS\zulu21.46.19-ca-jdk21.0.9-win_x64\bin;$env:PATH"
.\gradlew.bat bootRun
```

### 前端服务（已在运行）
```powershell
cd D:\code\MiniLPAS\web-frontend
npm run dev
```

## 🔧 测试 API

### 使用 PowerShell 测试：
```powershell
# 检查服务状态
Invoke-RestMethod -Uri "http://localhost:8080/api/devices/status" -Method Get

# 获取设备列表
Invoke-RestMethod -Uri "http://localhost:8080/api/devices" -Method Get

# 获取芯片信息
Invoke-RestMethod -Uri "http://localhost:8080/api/chip/info" -Method Get
```

### 使用浏览器测试：
- 访问: http://localhost:8080/api/devices/status
- 访问: http://localhost:8080/api/devices

## 📝 下一步

1. **访问前端界面**: 打开 http://localhost:3000
2. **连接本地代理**: 需要启动 `local-agent` 服务才能使用完整功能
3. **测试功能**: 尝试查看设备状态、芯片信息等

## ⚠️ 注意事项

- 后端服务需要 Java 21 环境
- 前端服务需要 Node.js 环境
- 本地代理服务需要 PCSC 支持（Windows 默认支持）
- 如果没有连接本地代理，部分功能可能无法使用

