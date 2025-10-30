# MiniLPAS - eSIM 管理平台

> 一个完整的 Web 化 eSIM 管理解决方案，支持通过浏览器管理 eSIM 配置文件和通知。

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Kotlin](https://img.shields.io/badge/kotlin-1.9+-blue.svg)](https://kotlinlang.org/)
[![React](https://img.shields.io/badge/react-18+-blue.svg)](https://reactjs.org/)
[![Spring Boot](https://img.shields.io/badge/spring%20boot-3.0+-green.svg)](https://spring.io/projects/spring-boot)

## 📋 项目简介

MiniLPAS（MiniLPA Web System）是一个基于 Web 的 eSIM 管理平台，允许用户通过浏览器方便地管理 eSIM 配置文件。系统采用前后端分离架构，提供现代化的 Web 界面和完整的 REST API。

### 核心功能

- ✅ **配置文件管理**：查看、安装、启用、禁用、删除 eSIM 配置
- ✅ **通知处理**：接收和处理来自运营商的通知
- ✅ **设备管理**：多设备支持，实时连接状态监控
- ✅ **芯片信息**：查看 eUICC 芯片详细信息
- ✅ **拖拽上传**：支持拖拽二维码和激活码上传
- ✅ **实时同步**：WebSocket 实时状态更新
- ✅ **响应式设计**：适配桌面和移动设备

## 🏗️ 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                      Web 浏览器                              │
│  React + TypeScript + Material-UI                           │
└───────────────────────┬─────────────────────────────────────┘
                        │ HTTP/WebSocket
                        │
┌───────────────────────▼─────────────────────────────────────┐
│              后端 Web API 服务                               │
│  Spring Boot 3 + Kotlin                                     │
│  - REST API                                                 │
│  - WebSocket Server                                         │
└───────────────────────┬─────────────────────────────────────┘
                        │ WebSocket
                        │
┌───────────────────────▼─────────────────────────────────────┐
│                 本地代理服务                                 │
│  Kotlin + PCSC + LPAC                                       │
│  - PCSC 连接管理                                            │
│  - LPAC 命令执行                                            │
└───────────────────────┬─────────────────────────────────────┘
                        │ PCSC
                        │
┌───────────────────────▼─────────────────────────────────────┐
│              智能卡/eSIM 设备                                │
└─────────────────────────────────────────────────────────────┘
```

## 📁 项目结构

```
MiniLPAS/
├── web-backend/          # 后端 Web API 服务
│   ├── src/
│   │   └── main/
│   │       ├── kotlin/   # Kotlin 源代码
│   │       └── resources/ # 配置文件
│   └── build.gradle.kts  # Gradle 构建配置
│
├── web-frontend/         # 前端 Web 应用
│   ├── Rhet/            # React 源代码
│   ├── public/          # 静态资源
│   └── package.json     # NPM 依赖配置
│
├── local-agent/          # 本地代理服务
│   ├── src/
│   │   └── main/
│   │       └── kotlin/   # Kotlin 源代码
│   └── build.gradle.kts  # Gradle 构建配置
│
├── deploy/               # 部署相关脚本和配置
│   ├── build-all.sh     # 构建脚本
│   ├── install.sh       # 安装脚本
│   └── *.service        # systemd 服务文件
│
├── .github/
│   └── workflows/
│       └── deploy.yml    # CI/CD 自动部署
│
└── docs/                 # 项目文档
    ├── WEB_ARCHITECTURE.md  # 架构设计文档
    ├── START_GUIDE.md       # 启动指南
    └── ...
```

## 🚀 快速开始

### 前置要求

- **Java**: JDK 21 或更高版本
- **Node.js**: 18 或更高版本
- **Gradle**: 7.5 或更高版本（项目包含 Gradle Wrapper）
- **PCSC**: 智能卡读取器驱动（用于本地代理）

### 本地开发

#### 1. 启动后端服务

```bash
cd web-backend
./gradlew bootRun
```

后端服务默认运行在 `http://localhost:8080`

#### 2. 启动本地代理服务

```bash
cd local-agent
./gradlew run
```

代理服务会连接到后端的 WebSocket 服务器。

#### 3. 启动前端应用

```bash
cd web-frontend
npm install
npm run dev
```

前端应用默认运行在 `http://localhost:3000`

#### 4. 访问应用

在浏览器中打开 `http://localhost:3000` 即可使用。

### 使用 Docker（可选）

```bash
# 构建后端镜像
cd web-backend
docker build -t minilpa-backend .

# 运行后端服务
docker run -p 8080:8080 minilpa-backend
```

## 📚 文档

- **[架构设计文档](WEB_ARCHITECTURE.md)** - 详细的系统架构说明
- **[快速启动指南](QUICK_START.md)** - 快速上手指南
- **[部署指南](deploy/DEPLOY.md)** - 生产环境部署说明
- **[API 文档](docs/API.md)** - REST API 接口文档（待完善）
- **[系统优化参考](系统优化参考文档.md)** - 优化建议和最佳实践
- **[故障排查指南](部署失败排查指南.md)** - 常见问题解决方案

## 🔧 开发

### 技术栈

**后端**：
- Spring Boot 3
- Kotlin
- WebSocket (Spring WebSocket)
- Gradle

**前端**：
- React 18
- TypeScript
- Material-UI (MUI)
- Vite

**本地代理**：
- Kotlin
- PCSC (智能卡接口)
- LPAC (Local Profile Assistant Client)

### 构建

```bash
# 有用的后端服务
cd web-backend
./gradlew build

# 构建前端
cd web-frontend
npm run build

# 构建所有组件
cd deploy
./build-all.sh
```

### 测试

```bash
# 运行后端测试
cd web-backend
./gradlew test

# 运行前端测试
cd web-frontend
npm test
```

## 🚢 部署

### 自动部署（推荐）

项目配置了 GitHub Actions 自动部署，推送代码到 `main` 分支后会自动构建并部署到服务器。

**配置要求**：
- 配置 GitHub Secrets（见 [CI_CD_SETUP.md](.github/CI_CD_SETUP.md)）
- 服务器 SSH 访问权限

### 手动部署

详细的手动部署步骤请参考 [部署指南](deploy/DEPLOY.md)。

## 🐛 故障排查

遇到问题时，请参考 [故障排查指南](部署失败排查指南.md음)。

常见问题：
- **前端显示"未连接"**：检查后端和代理服务是否启动
- **无法连接设备**：检查 PCSC 驱动和智能卡读取器
- **部署失败**：检查 GitHub Secrets 和服务器连接

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 🙏 致谢

- [MiniLPA](https://github.com/your-repo/minilpa) - 原始桌面应用项目
- [LPAC](https://github.com/estk/lpac) - Local Profile Assistant Client

## 📞 联系方式

- **Issues**: [GitHub Issues](https://github.com/your-repo/MiniLPAS/issues)
- **讨论**: [GitHub Discussions](https://github.com/your-repo/MiniLPAS/discussions)

---

**注意**：本项目仍在积极开发中，API 可能会有变化。
