# MiniLPAS 项目文档索引

欢迎查阅 MiniLPAS 项目文档。本文档提供所有文档的索引和快速导航。

## 📚 文档分类

### 🏗️ 架构设计

- **[系统架构设计](项目架构设计.md)** - 详细的系统架构设计文档
- **[Web 架构设计](../WEB_ARCHITECTURE.md)** - Web 化架构说明
- **[系统优化参考](../系统优化参考文档.md)** - 系统优化建议和最佳实践

### 🚀 快速开始

- **[快速启动指南](../QUICK_START.md)** - 快速上手指南
- **[运行项目指南](../RUN_PROJECT.md)** - 本地运行详细步骤
- **[启动指南](../START_GUIDE.md)** - 项目启动说明

### 🚢 部署运维

- **[部署指南](../deploy/DEPLOY.md)** - 生产环境部署说明
- **[快速部署](../QUICK_DEPLOY.md)** - 快速部署步骤
- **[CI/CD 配置](../.github/CI_CD_SETUP.md)** - GitHub Actions 配置说明
- **[SSH 密钥配置](../.github/SECRETS_GUIDE.md)** - SSH 密钥配置指南

### 🐛 故障排查

- **[故障排查指南](../TROUBLESHOOTING.md)** - 通用故障排查
- **[部署失败排查](../部署失败排查指南.md)** - 部署相关问题解决
- **[Nginx 配置修复](../Nginx配置修复方案.md)** - Nginx 配置问题

### 📋 项目管理

- **[项目状态](../PROJECT_STATUS.md)** - 当前项目状态
- **[功能实现](../FEATURES_IMPLEMENTED.md)** - 已实现功能列表
- **[实现计划](../IMPLEMENTATION_PLAN.md)** - 开发计划

### 🔧 开发文档

- **[部署管理脚本](../deploy/MANAGE_GUIDE.md)** - 服务器管理脚本使用
- **[LPAC 设置](../deploy/LPAC_SETUP.md)** - LPAC 环境配置
- **[LPAC 快速参考](../deploy/LPAC_QUICK_REF.md)** - LPAC 命令参考

### 📖 参考文档

- **[README](../README.md)** - 项目主文档
- **[Web 版本 README](../README_WEB.md)** - Web 版本说明

## 🔍 按使用场景查找

### 我是新用户，想快速开始

1. 阅读 [快速启动指南](../QUICK_START.md)
2. 查看 [运行项目指南](../RUN_PROJECT.md)
3. 如有问题，参考 [故障排查指南](../TROUBLESHOOTING.md)

### 我要部署到生产环境

1. 阅读 [部署指南](../deploy/DEPLOY.md)
2. 配置 [CI/CD](../.github/CI_CD_SETUP.md)
3. 查看 [Nginx 配置](../deploy/NGINX_GUIDE.md)
4. 遇到问题参考 [部署失败排查](../部署失败排查指南.md)

### 我要了解系统架构

1. 阅读 [系统架构设计](项目架构设计.md)
2. 查看 [Web 架构设计](../WEB_ARCHITECTURE.md)
3. 了解 [系统优化建议](../系统优化参考文档.md)

### 我要参与开发

1. 查看 [项目状态](../PROJECT_STATUS.md)
2. 了解 [实现计划](../IMPLEMENTATION_PLAN.md)
3. 参考 [系统优化文档](../系统优化参考文档.md) 的设计建议

### 我遇到了问题

1. 查看 [故障排查指南](../TROUBLESHOOTING.md)
2. 部署问题 → [部署失败排查](../部署失败排查指南.md)
3. 配置问题 → [Nginx 配置修复](../Nginx配置修复方案.md)
4. 服务管理 → [管理脚本指南](../deploy/MANAGE_GUIDE.md)

## 📝 文档维护

文档目录结构：
```
docs/                    # 文档目录
├── README.md           # 本文档（文档索引）
├── 项目架构设计.md     # 系统架构设计
├── ...                 # 其他文档

../                     # 项目根目录
├── README.md           # 项目主文档
├── QUICK_START.md      # 快速开始
├── deploy/             # 部署相关文档
├── .github/            # CI/CD 文档
└── ...                 # 其他文档
```

## 🔄 文档更新

文档会随着项目发展持续更新。如果发现文档有误或需要补充，请：

1. 提交 Issue 说明问题
2. 提交 Pull Request 改进文档
3. 在 Discussions 中讨论

---

**最后更新**：2025-10-30



