#!/bin/bash
# MiniLPA Web 一键安装脚本（在服务器上执行）
# 适用于宝塔Linux环境

set -e

echo "=== MiniLPA Web 安装脚本 ==="
echo ""

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

# 安装目录
INSTALL_DIR="/www/wwwroot/minilpa"
SERVICE_USER="www"

# 1. 创建目录结构
echo "1. 创建目录结构..."
mkdir -p "$INSTALL_DIR"/{app,frontend,config,logs,data}
chown -R $SERVICE_USER:$SERVICE_USER "$INSTALL_DIR"

# 2. 检查Java
echo "2. 检查Java环境..."
if ! command -v java &> /dev/null; then
    echo "错误: 未找到Java，请先安装Java 21"
    echo "Ubuntu/Debian: sudo apt install openjdk-21-jdk"
    echo "CentOS/RHEL: sudo yum install java-21-openjdk-devel"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | head -n 1)
echo "   找到Java: $JAVA_VERSION"

# 3. 检查并移动JAR文件
echo "3. 检查JAR文件..."

# 如果JAR文件在根目录，移动到app目录
if [ -f "$INSTALL_DIR/minilpa-backend.jar" ] && [ ! -f "$INSTALL_DIR/app/minilpa-backend.jar" ]; then
    echo "   移动 minilpa-backend.jar 到 app/ 目录..."
    mv "$INSTALL_DIR/minilpa-backend.jar" "$INSTALL_DIR/app/"
fi

if [ -f "$INSTALL_DIR/minilpa-agent.jar" ] && [ ! -f "$INSTALL_DIR/app/minilpa-agent.jar" ]; then
    echo "   移动 minilpa-agent.jar 到 app/ 目录..."
    mv "$INSTALL_DIR/minilpa-agent.jar" "$INSTALL_DIR/app/"
fi

# 检查JAR文件是否存在（在app目录中）
if [ ! -f "$INSTALL_DIR/app/minilpa-backend.jar" ]; then
    echo "错误: 未找到 minilpa-backend.jar"
    echo "请将构建好的文件上传到 $INSTALL_DIR/ 或 $INSTALL_DIR/app/"
    exit 1
fi

if [ ! -f "$INSTALL_DIR/app/minilpa-agent.jar" ]; then
    echo "错误: 未找到 minilpa-agent.jar"
    echo "请将构建好的文件上传到 $INSTALL_DIR/ 或 $INSTALL_DIR/app/"
    exit 1
fi

echo "   ✅ JAR文件检查通过"

# 4. 检查前端文件
echo "4. 检查前端文件..."
if [ ! -f "$INSTALL_DIR/frontend/index.html" ]; then
    echo "错误: 未找到前端文件"
    echo "请将构建好的前端文件上传到 $INSTALL_DIR/frontend/"
    exit 1
fi

echo "   ✅ 前端文件检查通过"

# 5. 配置systemd服务
echo "5. 配置systemd服务..."

# 查找Java路径
JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
echo "   检测到JAVA_HOME: $JAVA_HOME"

# 更新服务文件中的Java路径
sed -i "s|JAVA_HOME=.*|JAVA_HOME=$JAVA_HOME|g" "$INSTALL_DIR/config/minilpa-backend.service"
sed -i "s|JAVA_HOME=.*|JAVA_HOME=$JAVA_HOME|g" "$INSTALL_DIR/config/minilpa-agent.service"

# 复制服务文件
cp "$INSTALL_DIR/config/minilpa-backend.service" /etc/systemd/system/
cp "$INSTALL_DIR/config/minilpa-agent.service" /etc/systemd/system/

systemctl daemon-reload
echo "   ✅ systemd服务配置完成"

# 6. 安装PCSC（如果未安装）
echo "6. 检查PCSC服务..."
if ! command -v pcsc_scan &> /dev/null; then
    echo "   安装PCSC-Lite..."
    if command -v apt &> /dev/null; then
        apt update && apt install -y pcscd pcsc-tools libpcsclite-dev
    elif command -v yum &> /dev/null; then
        yum install -y pcsc-lite pcsc-lite-devel
    fi
fi

systemctl enable pcscd
systemctl start pcscd
echo "   ✅ PCSC服务配置完成"

# 7. 设置权限
echo "7. 设置文件权限..."
chown -R $SERVICE_USER:$SERVICE_USER "$INSTALL_DIR"
chmod +x "$INSTALL_DIR/app"/*.jar 2>/dev/null || true

# 查找并设置lpac权限
# 检查工作目录下的LPAC（local-agent的WorkingDirectory是 $INSTALL_DIR）
if [ -f "$INSTALL_DIR/linux-x86_64/lpac" ]; then
    chmod +x "$INSTALL_DIR/linux-x86_64/lpac"
    echo "   ✅ LPAC权限设置完成 (位于工作目录)"
elif [ -f "$INSTALL_DIR/lpac/linux-x86_64/lpac" ]; then
    chmod +x "$INSTALL_DIR/lpac/linux-x86_64/lpac"
    echo "   ✅ LPAC权限设置完成 (位于独立目录)"
    echo "   ⚠️  建议移动到: $INSTALL_DIR/linux-x86_64/lpac"
else
    echo "   ⚠️  LPAC文件未找到，请手动配置"
    echo "   位置: $INSTALL_DIR/linux-x86_64/lpac"
fi

# 8. 启动服务
echo "8. 启动服务..."
systemctl enable minilpa-backend
systemctl enable minilpa-agent
systemctl start minilpa-backend
systemctl start minilpa-agent

sleep 3

# 检查服务状态
if systemctl is-active --quiet minilpa-backend; then
    echo "   ✅ 后端服务启动成功"
else
    echo "   ⚠️  后端服务启动失败，请查看日志: sudo journalctl -u minilpa-backend -n 50"
fi

if systemctl is-active --quiet minilpa-agent; then
    echo "   ✅ 代理服务启动成功"
else
    echo "   ⚠️  代理服务启动失败，请查看日志: sudo journalctl -u minilpa-agent -n 50"
fi

echo ""
echo "=== 安装完成 ==="
echo ""
echo "下一步："
echo "1. 配置Nginx（参考 deploy/nginx.conf.example）"
echo "2. 在宝塔面板中创建网站，指向 $INSTALL_DIR/frontend"
echo "3. 访问网站验证部署"
echo ""
echo "查看服务状态:"
echo "  sudo systemctl status minilpa-backend"
echo "  sudo systemctl status minilpa-agent"
echo ""
echo "查看日志:"
echo "  sudo journalctl -u minilpa-backend -f"
echo "  sudo journalctl -u minilpa-agent -f"

