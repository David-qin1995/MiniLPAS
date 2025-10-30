# MiniLPA Web 版本启动指南

## 项目结构

```
MiniLPAS/
├── MiniLPA-main/          # 原始桌面应用（已存在）
├── web-backend/           # 后端 Web API 服务 ✅
├── web-frontend/          # 前端 Web 应用 ✅
├── local-agent/           # 本地代理服务 ✅
└── docs/                  # 文档
```

## 启动步骤

### 1. 启动后端 Web API 服务

```bash
cd web-backend

# 设置 Java 环境变量（如果还没有）
$env:JAVA_HOME="D:\code\MiniLPAS\zulu21.46.19-ca-jdk21.0.9-win_x64"
$env:PATH="D:\code\MiniLPAS\zulu21.46.19-ca-jdk21.0.9-win_x64\bin;$env:PATH"

# 启动服务
.\gradlew.bat bootRun
```

后端服务将在 `http://localhost:8080` 运行。

### 2. 启动本地代理服务

```bash
cd local-agent

# 设置 Java 环境变量
$env:JAVA_HOME="D:\code\MiniLPAS\zulu21.46.19-ca-jdk21.0.9-win_x64"
$env:PATH="D:\code\MiniLPAS\zulu21.46.19-ca-jdk21.0.9-win_x64\bin;$env:PATH"

# 启动代理（需要先构建，可能需要配置依赖 MiniLPA-main）
.\gradlew.bat run
```

代理服务将连接到后端 WebSocket 服务器。

### 3. 启动前端 Web 应用

```bash
cd web-frontend

# 安装依赖（首次运行）
npm install

# 启动开发服务器
npm run dev
```

前端应用将在 `http://localhost:3000` 运行。

## 使用流程

1. **启动所有服务**：
   - 后端 API（端口 8080）
   - 本地代理（连接 PCSC）
   - 前端应用（端口 3000）

2. **在浏览器中访问**：
   打开 `http://localhost:3000`

3. **检查连接状态**：
   - 前端会自动检测本地代理是否连接
   - 如果显示"未连接"，检查本地代理是否正在运行

4. **管理 eSIM**：
   - 查看芯片信息
   - 管理配置文件（启用、禁用、删除）
   - 下载新配置文件
   - 处理通知

## 注意事项

### 依赖关系

- **本地代理服务**需要访问 `MiniLPA-main` 项目的代码（LPACExecutor）
- 你可能需要在 `local-agent/build.gradle.kts` 中配置项目依赖
- 或者将 `MiniLPA-main` 构建为库并添加为依赖

### 配置修改

如果后端服务不在 `localhost:8080`，需要修改：

1. **前端代理配置**：`web-frontend/vite.config.ts`
2. **本地代理服务器地址**：`local-agent/src/main/kotlin/moe/sekiu/minilpa/agent/LocalAgent.kt`

### 开发建议

1. **后端 API**：继续完善 REST API 实现，连接真实业务逻辑
2. **本地代理**：完善 LPAC 命令转发和响应处理
3. **前端界面**：美化 UI，添加更多功能（拖拽上传、实时通知等）
4. **WebSocket**：实现实时状态更新和进度通知

## 故障排除

### 后端无法启动
- 检查 Java 21 是否正确安装
- 检查端口 8080 是否被占用
- 查看日志输出

򎜠### 本地代理无法连接
- 检查后端服务是否运行
- 检查 WebSocket 地址配置
- 检查 PCSC 服务是否可用

### 前端无法连接后端
- 检查后端服务是否运行
- 检查 CORS 配置
- 检查代理配置（vite.config.ts）

## 下一步开发

1. ✅ 完成基础架构
2. ⏳ 完善业务逻辑实现
3. ⏳ 添加用户认证和权限控制
4. ⏳ 优化 WebSocket 通信
5. ⏳ 完善错误处理和日志
6. ⏳ UNIT 测试和集成测试
7. ⏳ 部署和生产配置

