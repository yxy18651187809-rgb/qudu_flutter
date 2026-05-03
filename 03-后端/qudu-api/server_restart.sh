#!/bin/bash
echo "🔍 检查后端服务状态..."
pkill -f "node.*server.js" 2>/dev/null && echo "✅ 旧进程已停止" || echo "ℹ️  无运行中的服务"
sleep 2
echo "🚀 启动后端服务..."
npm start > /Users/yangxiaoyan/WorkBuddy/20260420213331/server_output.log 2>&1 &
sleep 3
if pgrep -f "node.*server.js" > /dev/null; then
  echo "✅ 后端服务启动成功"
else
  echo "❌ 后端服务启动失败，查看日志:"
  tail -20 /Users/yangxiaoyan/WorkBuddy/20260420213331/server_output.log
fi
