const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const config = require('./config');

// 路由
const authRoutes = require('./routes/auth');
const childRoutes = require('./routes/children');
const bookRoutes = require('./routes/books');

const app = express();

// ===== 中间件 =====
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// ===== 健康检查 =====
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    service: 'qudu-api',
    version: '1.0.0',
    mongodb: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected'
  });
});

// ===== API 路由 =====
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/user', authRoutes);  // profile 复用 auth 路由
app.use('/api/v1/children', childRoutes);
app.use('/api/v1/books', bookRoutes);

// ===== 404 处理 =====
app.use((req, res) => {
  res.status(404).json({
    code: 40401,
    data: null,
    message: '接口不存在'
  });
});

// ===== 全局错误处理 =====
app.use((err, req, res, next) => {
  console.error('[Global Error]', err);
  res.status(500).json({
    code: 50001,
    data: null,
    message: '服务端内部错误'
  });
});

// ===== 数据库连接与启动 =====
async function startServer() {
  try {
    // 连接 MongoDB
    await mongoose.connect(config.mongodb.uri);
    console.log(`[MongoDB] 已连接: ${config.mongodb.uri}`);
    
    // 启动服务
    app.listen(config.port, () => {
      console.log(`[Server] 字趣阅读API服务已启动`);
      console.log(`[Server] 端口: ${config.port}`);
      console.log(`[Server] 环境: ${config.sms.provider === 'mock' ? '开发(MOCK)' : '生产'}`);
      console.log(`[Server] 健康检查: http://localhost:${config.port}/health`);
    });
  } catch (err) {
    console.error('[Server] 启动失败:', err);
    process.exit(1);
  }
}

startServer();

module.exports = app;
