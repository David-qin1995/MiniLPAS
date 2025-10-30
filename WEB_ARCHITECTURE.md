# MiniLPA Web 化架构设计

## 整体架构

```
┌─────────────────┐
│  Web 浏览器     │
│  (React/Vue)    │
└────────┬────────┘
         │ HTTP/WebSocket
         │
┌────────▼────────────────────────┐
│  后端 Web API 服务              │
│  (Spring Boot + Kotlin)         │
│  - REST API                     │
│  - WebSocket Server             │
│  - 业务逻辑层                   │
└────────┬────────────────────────┘
         │ WebSocket
         │
┌────────▼────────────────────────┐
│  本地代理服务                   │
│  (Java/Kotlin 本地应用)         │
│  - PCSC 连接管理                │
│  - LPAC 命令执行                │
│  - 智能卡访问                   │
└────────┬────────────────────────┘
         │ PCSC
         │
┌────────▼────────────────────────┐
│  智能卡/eSIM 设备               │
└─────────────────────────────────┘
```

## 组件说明

### 1. 后端 Web API 服务
- **技术栈**: Spring Boot 3 + Kotlin + WebSocket
- **功能**:
  - 提供 REST API 接口
  - WebSocket 实时通信
  - 管理本地代理服务连接
  - 业务逻辑处理（用户、会话、权限等）

### 2. 前端 Web 应用
- **技术栈**: React + TypeScript + Material-UI / Vue 3 + Vite
- **功能**:
  - eSIM 管理界面
  - 配置文件列表
  - 通知管理
  - 拖拽上传二维码
  - 实时状态更新

### 3. 本地代理服务
- **技术栈**: Kotlin + PCSC + LPAC
- **功能**:
  - 连接本地 PCSC 服务
  - 执行 LPAC 命令
  - 转发智能卡数据
  - 处理本地智能卡事件

## 数据流

1. **用户操作** → Web 前端 → HTTP/WebSocket → 后端 API
2. **后端 API** → WebSocket → 本地代理服务
3. **本地代理服务** → PCSC → LPAC → 智能卡
4. **响应返回** ← 反向路径 ←

## API 设计

### REST API
- `GET /api/devices` - 获取设备列表
- `GET /api/chip/info` - 获取芯片信息
- `GET /api/profiles` - 获取配置文件列表
- `POST /api/profiles/download` - 下载配置文件
- `POST /api/profiles/{iccid}/enable` - 启用配置
- `POST /api/profiles/{iccid}/disable` - 禁用配置
- `DELETE /api/profiles/{iccid}` - 删除配置
- `GET /api/notifications` - 获取通知列表
- `POST /api/notifications/{seq}/process` - 处理通知

### WebSocket 消息
- 实时状态更新
- 命令执行进度
- 错误通知
- 设备连接状态

## 安全考虑

1. **本地代理认证**: 使用 token 或密钥认证
2. **HTTPS**: 确保通信加密
3. **CORS**: 配置跨域访问
4. **权限控制**: 验证用户权限
5. **输入验证**: 防止注入攻击

## 部署方案

1. **开发环境**: 本地运行所有组件
2. **生产环境**: 
   - Web 后端部署到服务器
   - 本地代理服务需要安装在用户电脑
   - 通过自动安装程序分发代理服务

