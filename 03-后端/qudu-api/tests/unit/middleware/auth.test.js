const authMiddleware = require('../../../src/middlewares/auth');
const { optionalAuth } = require('../../../src/middlewares/auth');
const { generateAccessToken, generateRefreshToken } = require('../../../src/utils/token');

// ===== Helpers =====
function createMockReqRes(headers = {}) {
  const req = { headers };
  const res = {
    statusCode: 200,
    body: null,
    status(code) { this.statusCode = code; return this; },
    json(data) { this.body = data; return this; }
  };
  let nextCalled = false;
  let nextError = null;
  const next = (err) => { if (err) nextError = err; else nextCalled = true; };
  return { req, res, next, wasNextCalled: () => nextCalled, getNextError: () => nextError };
}

// ===== authMiddleware Tests =====
describe('authMiddleware', () => {
  test('无 Authorization 头 → 401 TOKEN_INVALID', () => {
    const { req, res, next, wasNextCalled } = createMockReqRes();
    authMiddleware(req, res, next);
    expect(wasNextCalled()).toBe(false);
    expect(res.statusCode).toBe(401);
    expect(res.body.code).toBe(40102);
    expect(res.body.message).toContain('未提供认证令牌');
  });

  test('Authorization 头无 Bearer 前缀 → 401', () => {
    const { req, res, next, wasNextCalled } = createMockReqRes({ authorization: 'Basic abc123' });
    authMiddleware(req, res, next);
    expect(wasNextCalled()).toBe(false);
    expect(res.statusCode).toBe(401);
    expect(res.body.code).toBe(40102);
  });

  test('Bearer 后无 token → 401', () => {
    const { req, res, next, wasNextCalled } = createMockReqRes({ authorization: 'Bearer ' });
    authMiddleware(req, res, next);
    // Bearer + 空字符串 → verifyToken('') 会抛出 jwt error
    expect(wasNextCalled()).toBe(false);
    expect(res.statusCode).toBe(401);
  });

  test('有效 accessToken → next() + req.userId 被设置', () => {
    const token = generateAccessToken('user123');
    const { req, res, next, wasNextCalled } = createMockReqRes({ authorization: `Bearer ${token}` });
    authMiddleware(req, res, next);
    expect(wasNextCalled()).toBe(true);
    expect(req.userId).toBe('user123');
    expect(res.statusCode).toBe(200); // 没有被修改
  });

  test('refreshToken 而非 accessToken → 401 令牌类型错误', () => {
    const token = generateRefreshToken('user123');
    const { req, res, next, wasNextCalled } = createMockReqRes({ authorization: `Bearer ${token}` });
    authMiddleware(req, res, next);
    expect(wasNextCalled()).toBe(false);
    expect(res.statusCode).toBe(401);
    expect(res.body.code).toBe(40102);
    expect(res.body.message).toContain('令牌类型错误');
  });

  test('篡改签名的 token → 401 TOKEN_INVALID', () => {
    const token = generateAccessToken('user123');
    const tampered = token.slice(0, -5) + 'XXXXX'; // 篡改尾部签名
    const { req, res, next, wasNextCalled } = createMockReqRes({ authorization: `Bearer ${tampered}` });
    authMiddleware(req, res, next);
    expect(wasNextCalled()).toBe(false);
    expect(res.statusCode).toBe(401);
    expect(res.body.code).toBe(40102);
    expect(res.body.message).toContain('令牌无效');
  });

  test('完全伪造的 token → 401 TOKEN_INVALID', () => {
    const { req, res, next, wasNextCalled } = createMockReqRes({ authorization: 'Bearer eyJhbGciOiJIUzI1NiJ9.fakepayload.fakesign' });
    authMiddleware(req, res, next);
    expect(wasNextCalled()).toBe(false);
    expect(res.statusCode).toBe(401);
    expect(res.body.code).toBe(40102);
  });

  test('过期 accessToken → 401 TOKEN_EXPIRED', () => {
    const jwt = require('jsonwebtoken');
    const config = require('../../../src/config');
    // 手动签发一个1秒过期的token
    const expiredToken = jwt.sign(
      { userId: 'user_expired', type: 'access' },
      config.jwt.secret,
      { expiresIn: '1s' }
    );
    // 使用 jest fake timers 无法让 jwt.verify 识别过期
    // 直接用极短过期 + 等待
    const { req, res, next, wasNextCalled } = createMockReqRes({ authorization: `Bearer ${expiredToken}` });

    // 如果当前还没过期，先验证正常流程
    // 为了可靠测试过期，我们手动构造已过期的token
    const alreadyExpiredToken = jwt.sign(
      { userId: 'user_expired', type: 'access', exp: Math.floor(Date.now() / 1000) - 10 },
      config.jwt.secret
    );
    const req2 = { headers: { authorization: `Bearer ${alreadyExpiredToken}` } };
    const res2 = {
      statusCode: 200,
      body: null,
      status(code) { this.statusCode = code; return this; },
      json(data) { this.body = data; return this; }
    };
    let next2Called = false;
    authMiddleware(req2, res2, (err) => { if (!err) next2Called = true; });

    expect(next2Called).toBe(false);
    expect(res2.statusCode).toBe(401);
    expect(res2.body.code).toBe(40101);
    expect(res2.body.message).toContain('已过期');
  });

  test('不同 userId 格式都能正确设置到 req.userId', () => {
    const ids = ['user123', '507f1f77bcf86cd799439011', 'abc-def-ghi'];
    ids.forEach(userId => {
      const token = generateAccessToken(userId);
      const { req, res, next, wasNextCalled } = createMockReqRes({ authorization: `Bearer ${token}` });
      authMiddleware(req, res, next);
      expect(wasNextCalled()).toBe(true);
      expect(req.userId).toBe(userId);
    });
  });
});

// ===== optionalAuth Tests =====
describe('optionalAuth', () => {
  test('无 Authorization 头 → next()，req.userId 不设置', () => {
    const { req, res, next, wasNextCalled } = createMockReqRes();
    optionalAuth(req, res, next);
    expect(wasNextCalled()).toBe(true);
    expect(req.userId).toBeUndefined();
  });

  test('有效 accessToken → next() + req.userId 被设置', () => {
    const token = generateAccessToken('user456');
    const { req, res, next, wasNextCalled } = createMockReqRes({ authorization: `Bearer ${token}` });
    optionalAuth(req, res, next);
    expect(wasNextCalled()).toBe(true);
    expect(req.userId).toBe('user456');
  });

  test('refreshToken 而非 accessToken → next()，req.userId 不设置', () => {
    const token = generateRefreshToken('user456');
    const { req, res, next, wasNextCalled } = createMockReqRes({ authorization: `Bearer ${token}` });
    optionalAuth(req, res, next);
    expect(wasNextCalled()).toBe(true);
    expect(req.userId).toBeUndefined();
  });

  test('无效 token → next()，req.userId 不设置（公开接口容忍无效token）', () => {
    const { req, res, next, wasNextCalled } = createMockReqRes({ authorization: 'Bearer invalid.token.here' });
    optionalAuth(req, res, next);
    expect(wasNextCalled()).toBe(true);
    expect(req.userId).toBeUndefined();
  });

  test('过期 token → next()，req.userId 不设置', () => {
    const jwt = require('jsonwebtoken');
    const config = require('../../../src/config');
    const expiredToken = jwt.sign(
      { userId: 'user_expired', type: 'access', exp: Math.floor(Date.now() / 1000) - 10 },
      config.jwt.secret
    );
    const { req, res, next, wasNextCalled } = createMockReqRes({ authorization: `Bearer ${expiredToken}` });
    optionalAuth(req, res, next);
    expect(wasNextCalled()).toBe(true);
    expect(req.userId).toBeUndefined();
  });

  test('Authorization 头存在但格式错误（无 Bearer）→ next()，req.userId 不设置', () => {
    const { req, res, next, wasNextCalled } = createMockReqRes({ authorization: 'Basic abc123' });
    optionalAuth(req, res, next);
    expect(wasNextCalled()).toBe(true);
    expect(req.userId).toBeUndefined();
  });
});

// ===== ErrorCodes 响应格式验证 =====
describe('auth 错误响应格式', () => {
  test('所有 401 响应遵循 { code, data, message } 格式', () => {
    const scenarios = [
      { headers: {} },  // 无token
      { headers: { authorization: 'Basic xxx' } },  // 格式错误
      { headers: { authorization: 'Bearer invalid' } },  // 无效token
    ];

    scenarios.forEach(({ headers }) => {
      const { req, res, next } = createMockReqRes(headers);
      authMiddleware(req, res, next);
      expect(res.body).toHaveProperty('code');
      expect(res.body).toHaveProperty('data', null);
      expect(res.body).toHaveProperty('message');
      expect(typeof res.body.code).toBe('number');
      expect(typeof res.body.message).toBe('string');
    });
  });
});
