#!/bin/bash
# 更新部署脚本
# 用于快速更新已部署的服务

set -e

INSTALL_DIR="/www/wwwroot/minilpa"
BACKUP_DIR="$INSTALL_DIR/backup/$(date +%Y%m%d_%H%M%S)"

echo "=== MiniLPA Web 更新脚本 ==="
echo ""

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

# 1. 停止服务
echo "1. 停止服务..."
systemctl stop minilpa-backend 2>/dev/null || true
systemctl stop minilpa-agent 2>/dev/null || true
sleep 2

# 2. 备份旧文件
echo "2. 备份旧文件..."
mkdir -p "$BACKUP_DIR"
if [ -f "$INSTALL_DIR/app/minilpa-backend.jar" ]; then
    cp "$INSTALL_DIR/app/minilpa-backend.jar" "$BACKUP_DIR/"
fi
if [ -f "$INSTALL_DIR/app/minilpa-agent.jar" ]; then
    cp "$INSTALL_DIR/app/minilpa-agent.jar" "$BACKUP_DIR/"
fi
echo "   备份位置: $BACKUP_DIR"

# 3. 检查新文件
echo "3. 检查新文件..."
if [ ! -f "$INSTALL_DIR/app/minilpa-backend.jar.new" ] && [ ! -f "$INSTALL_DIR/app/minilpa-backend.jar" ]; then
    echo "错误: 未找到新的JAR文件"
    echo "请将新文件上传到 $INSTALL_DIR/app/ 目录"
    exit 1
fi

# 替换JAR文件（如果有.new文件，说明是新上传的）
if [ -f "$INSTALL_DIR/app/minilpa-backend.jar.new" ]; then
    mv "$INSTALL_DIR/app/minilpa-backend.jar.new" "$INSTALL_DIR/app/minilpa-backend.jar"
fi
if [ -f "$INSTALL_DIR/app/minilpa-agent.jar.new" ]; then
    mv "$INSTALL_DIR/app/minilpa-agent.jar.new" "$INSTALL_DIR/app/minilpa-agent.jar"
fi

# 4. 更新前端（如果有新的前端文件）
if [ -d "$INSTALL_DIR/frontend.new" ]; then
    echo "4. 更新前端文件..."
    if [ -d "$INSTALL_DIR/frontend" ]; then
        mv "$INSTALL_DIR/frontend" "$BACKUP_DIR/frontend"
    fi
    mv "$INSTALL_DIR/frontend.new" "$INSTALL_DIR/frontend"
    chown -R www:www "$INSTALL_DIR/frontend"
fi

# 5. 设置权限
chown www:www "$INSTALL_DIR/app"/*.jar
chmod 644 "$INSTALL_DIR/app"/*.jar

# 6. 启动服务
echo "5. 启动服务..."
systemctl start minilpa-backend
systemctl start minilpa-agent

sleep 3

# 检查服务状态
if systemctl is-active --quiet minilpa-backend; then
    echo "   ✅ 后端服务启动成功"
else
    echo "   ⚠️  后端服务启动失败"
    echo "   查看日志: sudo journalctl -u minilpa-backend -n 50"
fi

if systemctl is-active --quiet minilpa-agent; then
    echo "   ✅ 代理服务启动成功"
else
    echo "   ⚠️  代理服务启动失败"
    echo "   查看日志: sudo journalctl -u minilpa-agent -n 50"
fi

echo ""
echo "=== 更新完成 ==="
echo "备份位置: $BACKUP_DIR"

