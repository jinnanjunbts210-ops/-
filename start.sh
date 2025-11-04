#!/bin/bash

# 企业迷你云盘启动脚本

echo "==================================="
echo "    企业迷你云盘系统启动脚本"
echo "==================================="

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker未安装，请先安装Docker"
    exit 1
fi

# 检查Docker Compose是否安装
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose未安装，请先安装Docker Compose"
    exit 1
fi

echo "✅ Docker环境检查通过"

# 创建必要的目录
echo "📁 创建数据目录..."
mkdir -p data/mysql
mkdir -p data/redis
mkdir -p data/minio

# 停止可能存在的容器
echo "🛑 停止现有容器..."
docker-compose down

# 构建并启动服务
echo "🚀 启动服务..."
docker-compose up -d --build

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 30

# 检查服务状态
echo "🔍 检查服务状态..."
docker-compose ps

# 显示访问信息
echo ""
echo "==================================="
echo "        🎉 启动完成！"
echo "==================================="
echo "📱 前端应用：http://localhost"
echo "🔧 后端API：http://localhost:8080"
echo "💾 MinIO控制台：http://localhost:9001"
echo ""
echo "👤 默认管理员账号："
echo "   用户名：admin"
echo "   密码：123456"
echo ""
echo "📋 MinIO账号："
echo "   用户名：minioadmin"
echo "   密码：minioadmin"
echo ""
echo "🔍 查看日志：docker-compose logs -f"
echo "🛑 停止服务：docker-compose down"
echo "==================================="

