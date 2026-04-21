const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
const config = require('./config');

// 路由
const authRoutes = require('./routes/auth');
const childRoutes = require('./routes/children');
const bookRoutes = require('./routes/books');
const assessmentRoutes = require('./routes/assessments');
const learningRoutes = require('./routes/learning');

const app = express();

// ===== Swagger 文档配置 =====
const swaggerSpec = swaggerJsdoc({
  definition: {
    openapi: '3.0.0',
    info: {
      title: '字趣阅读 API',
      version: '1.2.0',
      description: '字趣阅读 - 5~12岁儿童AI识字阅读APP后端API文档\n\n## 认证方式\n所有需认证的接口请在Header中传入：`Authorization: Bearer <access_token>`\n\n## 错误码规范\n- 0: 成功\n- 40001-40099: 客户端参数错误\n- 40101-40199: 认证错误\n- 40301-40399: 权限错误\n- 40401: 接口不存在\n- 50001: 服务端内部错误',
      contact: {
        name: '字趣阅读后端团队'
      }
    },
    servers: [
      { url: 'http://localhost:3000', description: '开发环境' },
      { url: 'https://api.ziqu.com', description: '生产环境' }
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: '在登录接口获取的 access_token'
        }
      },
      schemas: {
        Error: {
          type: 'object',
          properties: {
            code: { type: 'integer', description: '错误码', example: 40001 },
            data: { type: 'object', nullable: true },
            message: { type: 'string', description: '错误信息', example: '参数错误' }
          }
        },
        Pagination: {
          type: 'object',
          properties: {
            page: { type: 'integer', example: 1 },
            pageSize: { type: 'integer', example: 20 },
            total: { type: 'integer', example: 100 },
            totalPages: { type: 'integer', example: 5 }
          }
        }
      }
    }
  },
  apis: ['./src/routes/*.js']
});

// Swagger UI
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: '字趣阅读 API 文档'
}));

// Swagger JSON（供前端代码生成用）
app.get('/api-docs.json', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.send(swaggerSpec);
});

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
app.use('/api/v1/assessments', assessmentRoutes);
app.use('/api/v1/learning', learningRoutes);

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
      console.log(`[Server] API文档: http://localhost:${config.port}/api-docs`);
    });
  } catch (err) {
    console.error('[Server] 启动失败:', err);
    process.exit(1);
  }
}

startServer();

module.exports = app;
