# MiniLPA Web 版本

这是 MiniLPA 的 Web 化改造版本，允许用户通过浏览器管理 eSIM 配置。

## 项目结构

```
MiniLPAS/
├── MiniLPA-main/          # 原始桌面应用
├── web-backend/           # 后端 Web API 服务
├── web-frontend/          # 前端 Web 应用
├── local-agent/           # 本地代理服务
└── docs/                  # 文档
```

## 快速开始

### 1. 后端服务

```bash
cd web-backend
./gradlew bootRun
```

后端服务默认运行在 `http://localhost:8080`

### 2. 本地代理服务

```bash
cd local-agent
./gradlew run
```

代理服务会连接到后端 WebSocket 服务器。

### 3. 前端应用

```bash
cd web-frontend
npm install
npm run dev
```

前端应用默认运行在 `http://localhost:3000`

## 功能特性

- ✅ 通过 Web 界面管理 eSIM
- ✅ 实时状态更新
- ✅ 拖拽上传二维码
 pairs
- ✅ 配置文件管理
- ✅ 通知处理
- ✅ 多语言支持
- ✅ 响应式设计

## 技术栈

- **后端**: Spring Boot 3 + Kotlin
- **前端**: React + TypeScript
- **本地代理**: Kotlin + PCSC
- **通信**: WebSocket + REST API

