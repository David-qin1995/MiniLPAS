# MiniLPA Web 功能实现计划

## 当前状态
✅ Web架构已搭建完成（前端、后端、本地代理）
✅ 代理连接已成功建立

## 缺失功能清单

### 1. 核心业务功能（高优先级）

#### 1.1 芯片信息获取
- [x] 架构已搭建
- [ ] 集成 LPACExecutor.getChipInfo()
- [ ] 实现真实数据返回（EID, ICCID, defaultSmdp等）

#### 1.2 配置文件管理
- [x] 架构已搭建
- [ ] 集成 LPACExecutor.getProfileList()
- [ ] 实现启用配置文件（enableProfile）
- [ ] 实现禁用配置文件（disableProfile）
- [ ] 实现删除配置文件（deleteProfile）
- [ ] 实现设置配置文件昵称（setProfileNickname）

#### 1.3 配置文件下载
- [x] 架构已搭建
- [ ] 集成 LPACExecutor.downloadProfile()
- [ ] 实现激活码解析
- [ ] 实现QR码解析（支持拖放和粘贴）
- [ ] 实现下载进度显示

#### 1.4 通知管理
- [ ] 获取通知列表（getNotificationList）
- [ ] 处理通知（processNotification）
- [ ] 删除通知（removeNotification）

### 2. 前端增强功能（中优先级）

#### 2.1 QR码处理
- [ ] 拖放QR码图片解析
- [ ] 粘贴QR码图片解析
- [ ] QR码激活码文本解析

#### 2.2 用户体验
- [ ] 搜索和快速导航
- [ ] 多语言支持（i18n）
- [ ] 主题切换（日/夜模式）
- [ ] 配置文件图标显示
- [ ] 进度显示和通知

#### 2.3 批量操作
- [ ] 批量选择配置文件
- [ ] 批量删除/启用/禁用

### 3. 技术集成（高优先级）

#### 3.1 LPACExecutor集成
- [ ] 将 MiniLPA-main 构建为库或复制核心代码
- [ ] 在 local-agent 中集成 LPACExecutor
- [ ] 处理 PCSC 设备检测和选择
- [ ] 处理 LPAC 命令执行

#### 3.2 数据模型
- [ ] 对齐 ChipInfo 模型
- [ ] 对齐 Profile 模型
- [ ] 对齐 DownloadInfo 模型
- [ ] 对齐 Notification 模型

## 实施步骤

### 阶段1：核心功能集成（最优先）
1. 集成 LPACExecutor 到 local-agent
2. 实现 getChipInfo
3. 实现 getProfileList
4. 实现 enable/disable/delete Profile

### 阶段2：下载功能
1. 实现 downloadProfile
2. 前端添加QR码解析
3. 实现下载进度显示

### 阶段3：通知管理
1. 实现 getNotificationList
2. 实现 processNotification
3. 实现 removeNotification

### 阶段4：前端增强
1. 搜索功能
2. 多语言支持
3. 主题切换

## 技术挑战

1. **LPACExecutor依赖**：需要将 MiniLPA-main 的代码集成到 local-agent
   - 方案A：将 MiniLPA-main 构建为 Gradle 子模块
   - 方案B：复制必要的类到 local-agent
   - 方案C：使用 JAR 依赖

2. **PCSC设备管理**：需要在代理中处理设备列表和选择
3. **LPAC可执行文件**：需要确保 lpac 二进制文件可用
4. **进度报告**：需要通过 WebSocket 实时报告操作进度

