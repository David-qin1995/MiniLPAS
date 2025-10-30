#!/bin/bash
# 一键构建脚本 - 用于宝塔Linux部署
# 构建所有组件并生成可部署文件

set -e

echo "=== MiniLPA Web 项目构建脚本 ==="
echo ""

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/deploy/build"
DIST_DIR="$PROJECT_ROOT/deploy/dist"

mkdir -p "$BUILD_DIR" "$DIST_DIR"

# 检查Java环境
if [ -z "$JAVA_HOME" ]; then
    echo "错误: 请设置 JAVA_HOME 环境变量（需要Java 21）"
    exit 1
fi

echo "Java版本:"
"$JAVA_HOME/bin/java" -version

echo ""
echo "1. 构建后端服务..."
cd "$PROJECT_ROOT/web-backend"
./gradlew clean bootJar --no-daemon
cp build/libs/*.jar "$DIST_DIR/minilpa-backend.jar"
echo "✅ 后端构建完成"

echo ""
echo "2. 构建本地代理..."
cd "$PROJECT_ROOT/local-agent"
./gradlew clean build --no-daemon
cp build/libs/*.jar "$DIST_DIR/minilpa-agent.jar"
cp -r "$PROJECT_ROOT/MiniLPA-main/windows_x86" "$DIST_DIR/lpac" 2>/dev/null || echo "⚠️  lpac目录未找到，需要在部署后手动配置"
echo "✅ 代理构建完成"

echo ""
echo "3. 构建前端..."
cd "$PROJECT_ROOT/web-frontend"
if [ ! -d "node_modules" ]; then
    echo "安装前端依赖..."
    npm install
fi
npm run build
cp -r dist "$DIST_DIR/frontend"
echo "✅ 前端构建完成"

echo ""
echo "4. 创建部署配置文件..."
cd "$PROJECT_ROOT/deploy"

# 创建部署目录结构
mkdir -p "$DIST_DIR/app" "$DIST_DIR/config" "$DIST_DIR/logs"
cp nginx.conf.example "$DIST_DIR/config/"
cp minilpa-backend.service "$DIST_DIR/config/"
cp minilpa-agent.service "$DIST_DIR/config/"

echo ""
echo "=== 构建完成 ==="
echo "部署文件位置: $DIST_DIR"
echo ""
echo "文件列表:"
ls -lh "$DIST_DIR"
echo ""
echo "下一步:"
echo "1. 将 $DIST_DIR 目录上传到服务器"
echo "2. 按照 DEPLOY.md 文档进行部署"

