const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
const path = require('path');
const config = require('./config');
const logger = require('./utils/logger');

// 路由
const authRoutes = require('./routes/auth');
const childRoutes = require('./routes/children');
const bookRoutes = require('./routes/books');
const characterRoutes = require('./routes/characters');
const assessmentRoutes = require('./routes/assessments');
const learningRoutes = require('./routes/learning');
const learningReportRoutes = require('./routes/learningReport');
const parentMonitoringRoutes = require('./routes/parentMonitoring');
const ttsRoutes = require('./routes/tts');
const requestLogger = require('./middlewares/requestLogger');
const { validateConfig } = require('./middlewares/configValidator');

const app = express();

// ===== 信任反向代理（Nginx/ALB 后获取真实 IP） =====
app.set('trust proxy', 1);

// ===== Swagger 文档配置 =====
const swaggerSpec = swaggerJsdoc({
  definition: {
    openapi: '3.0.0',
    info: {
      title: '字趣阅读 API',
      version: '1.3.0',
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

// 1. 安全 headers (helmet)
app.use(helmet());

// 2. CORS 严格配置
app.use(cors({
  origin: function(origin, callback) {
    // 允许没有 origin 的请求（如 Postman、curl）
    if (!origin) return callback(null, true);
    
    const allowedOrigins = config.security.corsOrigins;
    if (allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      logger.warn(`[CORS] 拒绝来源: ${origin}`);
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

// 3. 全局速率限制
app.use(rateLimit({
  windowMs: config.security.rateLimit.default.windowMs,
  max: config.security.rateLimit.default.max,
  message: { code: 42901, data: null, message: '请求过于频繁，请稍后再试' },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    logger.warn(`[RateLimit] IP=${req.ip} ${req.method} ${req.originalUrl}`);
    res.status(429).json({
      code: 42901,
      data: null,
      message: '请求过于频繁，请稍后再试'
    });
  }
}));

// 4. 请求日志
app.use(morgan('dev'));
app.use(requestLogger);  // 自定义请求日志（响应时间、慢请求告警）
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// ===== 静态文件服务 =====
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));
app.use('/audio', express.static(path.join(__dirname, '..', 'uploads', 'audio')));
app.use('/audio/books', express.static(path.join(__dirname, '..', 'uploads', 'audio', 'books')));

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

// ===== 认证接口严格速率限制 =====
const authRateLimiter = rateLimit({
  windowMs: config.security.rateLimit.auth.windowMs,
  max: config.security.rateLimit.auth.max,
  message: { code: 42902, data: null, message: config.security.rateLimit.auth.message },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    // 标准化 IPv6 映射地址（::ffff:127.0.0.1 → 127.0.0.1）
    const ip = (req.ip || '').replace(/^::ffff:/, '');
    return ip + ':' + (req.body?.phone || req.body?.username || 'unknown');
  }
});

// ===== TTS 接口速率限制（防止音频生成滥用） =====
const ttsRateLimiter = rateLimit({
  windowMs: config.security.rateLimit.tts.windowMs,
  max: config.security.rateLimit.tts.max,
  message: { code: 42904, data: null, message: config.security.rateLimit.tts.message },
  standardHeaders: true,
  legacyHeaders: false
});

app.use('/api/v1/auth', authRateLimiter, authRoutes);
app.use('/api/v1/user', authRateLimiter, authRoutes);  // profile 复用 auth 路由
// 短信验证码接口使用最严格限制（挂载在 auth 路由内部通过中间件实现）
app.use('/api/v1/children', childRoutes);
app.use('/api/v1/books', bookRoutes);
app.use('/api/v1/characters', characterRoutes);
app.use('/api/v1/assessments', assessmentRoutes);
app.use('/api/v1/learning', learningRoutes);
app.use('/api/v1/learning-report', learningReportRoutes);
app.use('/api/v1/parent-monitoring', parentMonitoringRoutes);
app.use('/api/v1/tts', ttsRateLimiter, ttsRoutes);

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
  // Mongoose 验证错误
  if (err.name === 'ValidationError') {
    const messages = Object.values(err.errors).map(e => e.message);
    logger.warn(`[Validation] ${req.method} ${req.originalUrl}: ${messages.join('; ')}`);
    return res.status(400).json({
      code: 40010,
      data: null,
      message: `参数校验失败: ${messages.join('; ')}`
    });
  }
  
  // Mongoose CastError（无效ID等）
  if (err.name === 'CastError') {
    logger.warn(`[CastError] ${req.method} ${req.originalUrl}: ${err.path}=${err.value}`);
    return res.status(400).json({
      code: 40010,
      data: null,
      message: `无效的${err.path}: ${err.value}`
    });
  }
  
  // JSON 解析错误
  if (err.type === 'entity.parse.failed') {
    logger.warn(`[ParseError] ${req.method} ${req.originalUrl}: 无效的JSON`);
    return res.status(400).json({
      code: 40010,
      data: null,
      message: '请求体JSON格式错误'
    });
  }
  
  // 未知错误
  logger.error(`[Global Error] ${req.method} ${req.originalUrl} requestId=${req.requestId || 'unknown'}`, err);
  res.status(500).json({
    code: 50001,
    data: null,
    message: process.env.NODE_ENV === 'production' ? '服务端内部错误' : `服务端内部错误: ${err.message}`
  });
});

// ===== 数据库连接与启动 =====
async function startServer() {
  try {
    // 启动前配置校验（生产环境不安全配置将拒绝启动）
    validateConfig(config);

    // 连接 MongoDB
    await mongoose.connect(config.mongodb.uri);
    logger.info(`[MongoDB] 已连接: ${config.mongodb.uri}`);
    
    const server = app.listen(config.port, () => {
      logger.info('[Server] 字趣阅读API服务已启动');
      logger.info(`[Server] 端口: ${config.port}`);
      logger.info(`[Server] 环境: ${config.sms.provider === 'mock' ? '开发(MOCK)' : '生产'}`);
      logger.info(`[Server] 健康检查: http://localhost:${config.port}/health`);
      logger.info(`[Server] API文档: http://localhost:${config.port}/api-docs`);
    });

    // ===== 优雅关闭 =====
    const gracefulShutdown = async (signal) => {
      logger.info(`[Server] 收到 ${signal} 信号，开始优雅关闭...`);
      
      // 1. 停止接收新请求
      server.close(() => {
        logger.info('[Server] HTTP 服务已关闭');
      });

      // 2. 断开数据库连接
      try {
        await mongoose.disconnect();
        logger.info('[MongoDB] 连接已关闭');
      } catch (err) {
        logger.error('[MongoDB] 关闭失败:', err.message);
      }

      // 3. 断开 Redis（如果已连接）
      try {
        const Redis = require('ioredis');
        const redis = new Redis(config.redis.url, { lazyConnect: true });
        try {
          await redis.connect();
          await redis.quit();
          logger.info('[Redis] 连接已关闭');
        } catch {
          // Redis 未连接，跳过
        }
      } catch {
        // Redis 模块加载失败，跳过
      }

      logger.info('[Server] 优雅关闭完成');
      process.exit(0);
    };

    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
    process.on('SIGINT', () => gracefulShutdown('SIGINT'));
    process.on('unhandledRejection', (reason) => {
      logger.error('[Server] 未处理的Promise拒绝:', reason);
    });
    process.on('uncaughtException', (err) => {
      logger.error('[Server] 未捕获的异常:', err);
      gracefulShutdown('UNCAUGHT_EXCEPTION');
    });

  } catch (err) {
    logger.error('[Server] 启动失败:', err);
    process.exit(1);
  }
}

// 仅直接执行时启动服务器，被 require 时不自动启动（支持测试）
if (require.main === module) {
  startServer();
}

module.exports = app;
