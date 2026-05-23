const { validateConfig, validateProductionConfig, validateDevConfig } = require('../../../src/middlewares/configValidator');
const logger = require('../../../src/utils/logger');

// Mock logger
jest.mock('../../../src/utils/logger', () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn()
}));

describe('configValidator', () => {
  const originalEnv = process.env.NODE_ENV;

  beforeEach(() => {
    jest.clearAllMocks();
  });

  afterAll(() => {
    process.env.NODE_ENV = originalEnv;
  });

  // ===== 生产环境校验 =====
  describe('validateProductionConfig', () => {
    const safeConfig = {
      jwt: { secret: 'a'.repeat(64) },
      mongodb: { uri: 'mongodb+srv://user:pass@cluster.mongodb.net/qudu' },
      sms: { provider: 'qcloud' },
      wechat: { appId: 'wx1234567890abcdef', appSecret: 'real-secret-key-32chars!' },
      security: { corsOrigins: ['https://app.ziqu.com'] }
    };

    test('安全配置应通过校验', () => {
      expect(() => validateProductionConfig(safeConfig)).not.toThrow();
    });

    test('JWT_SECRET 为默认值应抛出错误', () => {
      const config = { ...safeConfig, jwt: { secret: 'dev-secret-change-in-production' } };
      expect(() => validateProductionConfig(config)).toThrow('JWT_SECRET');
      expect(logger.error).toHaveBeenCalled();
    });

    test('JWT_SECRET 长度不足应抛出错误', () => {
      const config = { ...safeConfig, jwt: { secret: 'short' } };
      expect(() => validateProductionConfig(config)).toThrow('32');
    });

    test('MONGODB_URI 指向 localhost 应抛出错误', () => {
      const config = { ...safeConfig, mongodb: { uri: 'mongodb://localhost:27017/qudu' } };
      expect(() => validateProductionConfig(config)).toThrow('本地地址');
    });

    test('MONGODB_URI 指向 127.0.0.1 应抛出错误', () => {
      const config = { ...safeConfig, mongodb: { uri: 'mongodb://127.0.0.1:27017/qudu' } };
      expect(() => validateProductionConfig(config)).toThrow('本地地址');
    });

    test('SMS 为 mock 模式应产生警告', () => {
      const config = { ...safeConfig, sms: { provider: 'mock' } };
      validateProductionConfig(config);
      expect(logger.warn).toHaveBeenCalled();
    });

    test('微信配置为 mock 应产生警告', () => {
      const config = { ...safeConfig, wechat: { appId: 'mock', appSecret: 'mock' } };
      validateProductionConfig(config);
      expect(logger.warn).toHaveBeenCalled();
    });

    test('CORS 仅包含 localhost 应产生警告', () => {
      const config = { ...safeConfig, security: { corsOrigins: ['http://localhost:3000'] } };
      validateProductionConfig(config);
      expect(logger.warn).toHaveBeenCalled();
    });

    test('CORS 为空应抛出错误', () => {
      const config = { ...safeConfig, security: { corsOrigins: [] } };
      expect(() => validateProductionConfig(config)).toThrow('CORS_ORIGINS');
    });
  });

  // ===== 开发环境校验 =====
  describe('validateDevConfig', () => {
    test('默认配置应产生提醒', () => {
      const config = {
        jwt: { secret: 'dev-secret-change-in-production' },
        mongodb: { uri: 'mongodb://localhost:27017/qudu' },
        sms: { provider: 'mock' }
      };
      validateDevConfig(config);
      expect(logger.info).toHaveBeenCalled();
    });

    test('非默认配置不应产生提醒', () => {
      jest.clearAllMocks();
      const config = {
        jwt: { secret: 'a'.repeat(64) },
        mongodb: { uri: 'mongodb+srv://cluster.mongodb.net/qudu' },
        sms: { provider: 'qcloud' }
      };
      validateDevConfig(config);
      expect(logger.info).not.toHaveBeenCalledWith(
        expect.stringContaining('JWT_SECRET')
      );
    });
  });

  // ===== validateConfig 入口 =====
  describe('validateConfig', () => {
    test('生产环境应调用 validateProductionConfig', () => {
      process.env.NODE_ENV = 'production';
      const config = {
        jwt: { secret: 'a'.repeat(64) },
        mongodb: { uri: 'mongodb+srv://cluster.mongodb.net/qudu' },
        sms: { provider: 'qcloud' },
        wechat: { appId: 'wx1234', appSecret: 'real-key' },
        security: { corsOrigins: ['https://app.ziqu.com'] }
      };
      expect(() => validateConfig(config)).not.toThrow();
      delete process.env.NODE_ENV;
    });

    test('开发环境应调用 validateDevConfig', () => {
      delete process.env.NODE_ENV;
      const config = {
        jwt: { secret: 'dev-secret-change-in-production' },
        mongodb: { uri: 'mongodb://localhost:27017/qudu' },
        sms: { provider: 'mock' }
      };
      expect(() => validateConfig(config)).not.toThrow();
    });
  });
});
