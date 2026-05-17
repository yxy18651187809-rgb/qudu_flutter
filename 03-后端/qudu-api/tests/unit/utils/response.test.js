/**
 * 字趣阅读 - utils/response 单元测试
 */

const { success, created, error, fail, paginate, ErrorCodes } = require('../../../src/utils/response');

// Mock res 对象
function mockRes() {
  const res = {
    statusCode: null,
    body: null,
    status(code) {
      res.statusCode = code;
      return res;
    },
    json(data) {
      res.body = data;
      return res;
    }
  };
  return res;
}

describe('utils/response', () => {
  describe('success()', () => {
    test('默认返回200和成功响应', () => {
      const res = mockRes();
      success(res, { id: 1 });

      expect(res.statusCode).toBe(200);
      expect(res.body).toEqual({
        code: 0,
        data: { id: 1 },
        message: 'success'
      });
    });

    test('自定义message', () => {
      const res = mockRes();
      success(res, null, '操作成功');

      expect(res.body.message).toBe('操作成功');
    });

    test('自定义statusCode', () => {
      const res = mockRes();
      success(res, { ok: true }, 'done', 202);

      expect(res.statusCode).toBe(202);
      expect(res.body.code).toBe(0);
    });

    test('data默认为null', () => {
      const res = mockRes();
      success(res);

      expect(res.body.data).toBeNull();
    });
  });

  describe('created()', () => {
    test('返回201状态码', () => {
      const res = mockRes();
      created(res, { id: 'abc' });

      expect(res.statusCode).toBe(201);
      expect(res.body).toEqual({
        code: 0,
        data: { id: 'abc' },
        message: 'success'
      });
    });

    test('自定义message', () => {
      const res = mockRes();
      created(res, null, '创建成功');

      expect(res.body.message).toBe('创建成功');
    });
  });

  describe('error()', () => {
    test('默认返回400状态码', () => {
      const res = mockRes();
      error(res, 40001, '参数错误');

      expect(res.statusCode).toBe(400);
      expect(res.body).toEqual({
        code: 40001,
        data: null,
        message: '参数错误'
      });
    });

    test('自定义statusCode', () => {
      const res = mockRes();
      error(res, 40401, '不存在', 404);

      expect(res.statusCode).toBe(404);
      expect(res.body.code).toBe(40401);
    });

    test('认证错误返回401', () => {
      const res = mockRes();
      error(res, 40101, 'Token过期', 401);

      expect(res.statusCode).toBe(401);
    });

    test('服务端错误返回500', () => {
      const res = mockRes();
      error(res, 50001, '内部错误', 500);

      expect(res.statusCode).toBe(500);
    });
  });

  describe('fail()', () => {
    test('返回错误对象（不调用res）', () => {
      const result = fail(40001, '参数错误');

      expect(result).toEqual({
        code: 40001,
        data: null,
        message: '参数错误'
      });
    });
  });

  describe('paginate()', () => {
    test('正确计算分页信息', () => {
      const result = paginate(1, 20, 100);

      expect(result).toEqual({
        page: 1,
        pageSize: 20,
        total: 100,
        totalPages: 5
      });
    });

    test('不满一页时totalPages为1', () => {
      const result = paginate(1, 20, 15);

      expect(result.totalPages).toBe(1);
    });

    test('刚好整除', () => {
      const result = paginate(2, 10, 30);

      expect(result.totalPages).toBe(3);
    });

    test('有余数时向上取整', () => {
      const result = paginate(1, 10, 11);

      expect(result.totalPages).toBe(2);
    });

    test('字符串数字会被转为Number', () => {
      const result = paginate('1', '20', 50);

      expect(result.page).toBe(1);
      expect(result.pageSize).toBe(20);
      expect(typeof result.page).toBe('number');
    });

    test('total为0时totalPages为0', () => {
      const result = paginate(1, 20, 0);

      expect(result.totalPages).toBe(0);
    });
  });

  describe('ErrorCodes', () => {
    test('包含所有预定义错误码', () => {
      expect(ErrorCodes.INVALID_PHONE).toBe(40001);
      expect(ErrorCodes.INVALID_SMS_CODE).toBe(40002);
      expect(ErrorCodes.SMS_CODE_EXPIRED).toBe(40003);
      expect(ErrorCodes.INVALID_PARAMS).toBe(40010);
      expect(ErrorCodes.TOKEN_EXPIRED).toBe(40101);
      expect(ErrorCodes.TOKEN_INVALID).toBe(40102);
      expect(ErrorCodes.FORBIDDEN).toBe(40301);
      expect(ErrorCodes.NOT_FOUND).toBe(40401);
      expect(ErrorCodes.SMS_RATE_LIMIT).toBe(42901);
      expect(ErrorCodes.INTERNAL_ERROR).toBe(50001);
    });

    test('错误码按类别分段', () => {
      // 参数类 40001-40099
      const paramCodes = Object.entries(ErrorCodes)
        .filter(([k]) => !['TOKEN', 'REFRESH', 'FORBIDDEN', 'MAX', 'CHILD_ACCESS', 'NOT_FOUND', 'CHILD_NOT', 'USER_NOT', 'REPORT_NOT', 'SMS_RATE', 'INTERNAL', 'SMS_SEND', 'GENERATE'].some(p => k.startsWith(p)))
        .filter(([, v]) => v >= 40000 && v < 40100);
      expect(paramCodes.length).toBeGreaterThan(0);

      // 认证类 40101-40199
      const authCodes = Object.values(ErrorCodes).filter(v => v >= 40100 && v < 40200);
      expect(authCodes.length).toBeGreaterThan(0);

      // 服务端 50001-50099
      const serverCodes = Object.values(ErrorCodes).filter(v => v >= 50000 && v < 50100);
      expect(serverCodes.length).toBeGreaterThan(0);
    });
  });
});
