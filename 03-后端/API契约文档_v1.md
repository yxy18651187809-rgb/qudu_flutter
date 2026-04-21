# 字趣阅读 - API 契约文档

**版本**：v1.0  
**日期**：2026-04-21  
**作者**：后端负责人  
**状态**：已交付，前端可按此开发

---

## 一、通用约定

### 1.1 Base URL

```
开发环境：http://localhost:3000/api/v1
生产环境：https://api.ziqu.com/api/v1
```

### 1.2 标准响应格式

```json
// 成功响应
{
  "code": 0,
  "data": { ... },
  "message": "success"
}

// 错误响应
{
  "code": 40001,
  "data": null,
  "message": "手机号格式不正确"
}

// 分页响应
{
  "code": 0,
  "data": {
    "list": [...],
    "pagination": {
      "page": 1,
      "pageSize": 20,
      "total": 100,
      "totalPages": 5
    }
  },
  "message": "success"
}
```

### 1.3 错误码规划

| 错误码范围 | 说明 | 示例 |
|-----------|------|------|
| 0 | 成功 | - |
| 40001-40099 | 参数校验错误 | 40001: 手机号格式不正确 |
| 40101-40199 | 认证错误 | 40101: Token已过期 |
| 40301-40399 | 权限错误 | 40301: 无权访问该儿童档案 |
| 40401-40499 | 资源不存在 | 40401: 绘本不存在 |
| 42901-42999 | 限流错误 | 42901: 发送过于频繁 |
| 50001-50099 | 服务端错误 | 50001: 内部错误 |

### 1.4 认证方式

所有需要认证的接口需在 Header 中携带：

```
Authorization: Bearer <accessToken>
```

### 1.5 通用错误响应

| HTTP Status | 含义 |
|-------------|------|
| 400 | 请求参数错误 |
| 401 | 未认证 / Token 过期 |
| 403 | 无权限 |
| 404 | 资源不存在 |
| 429 | 请求过于频繁 |
| 500 | 服务端内部错误 |

---

## 二、用户认证模块

### 2.1 发送验证码

```
POST /api/v1/auth/sms/send
```

**Request:**

```json
{
  "phone": "13800138000"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| phone | String | 是 | 手机号，11位 |

**Response 200:**

```json
{
  "code": 0,
  "data": {
    "expireIn": 300
  },
  "message": "success"
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| data.expireIn | Number | 验证码有效期（秒） |

**Error 400:**

```json
{ "code": 40001, "data": null, "message": "手机号格式不正确" }
```

**Error 429:**

```json
{ "code": 42901, "data": null, "message": "发送过于频繁，请60秒后重试" }
```

**限制：**
- 同一手机号 60 秒内只能发送 1 次
- 同一手机号每天最多 10 次

---

### 2.2 登录（手机号+验证码）

```
POST /api/v1/auth/login
```

**Request:**

```json
{
  "phone": "13800138000",
  "smsCode": "123456"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| phone | String | 是 | 手机号 |
| smsCode | String | 是 | 6位验证码 |

**Response 200（已注册用户）:**

```json
{
  "code": 0,
  "data": {
    "isNewUser": false,
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "dGhpcyBpcyBhIHJlZnJl...",
    "expiresIn": 7200,
    "user": {
      "id": "6801234567890abcdef12345",
      "phone": "138****8000",
      "nickname": "小明妈妈",
      "avatar": "https://cdn.ziqu.com/avatars/default.png",
      "hasChildren": true,
      "childrenCount": 1
    }
  },
  "message": "success"
}
```

**Response 200（新用户自动注册）:**

```json
{
  "code": 0,
  "data": {
    "isNewUser": true,
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "dGhpcyBpcyBhIHJlZnJl...",
    "expiresIn": 7200,
    "user": {
      "id": "6801234567890abcdef12346",
      "phone": "138****8000",
      "nickname": "",
      "avatar": "",
      "hasChildren": false,
      "childrenCount": 0
    }
  },
  "message": "success"
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| data.isNewUser | Boolean | 是否新注册用户 |
| data.accessToken | String | 访问令牌，2小时有效 |
| data.refreshToken | String | 刷新令牌，7天有效 |
| data.expiresIn | Number | accessToken 有效期（秒） |
| data.user.id | String | 用户ID |
| data.user.phone | String | 脱敏手机号 |
| data.user.nickname | String | 昵称 |
| data.user.avatar | String | 头像URL |
| data.user.hasChildren | Boolean | 是否已有儿童档案 |
| data.user.childrenCount | Number | 儿童档案数量 |

**Error 400:**

```json
{ "code": 40002, "data": null, "message": "验证码错误" }
```

```json
{ "code": 40003, "data": null, "message": "验证码已过期" }
```

**说明：**
- 登录接口同时处理「登录」和「注册」——新手机号自动注册
- 通过 `isNewUser` 字段区分新用户，前端可引导创建儿童档案
- 手机号返回时做脱敏处理（中间4位用****替代）

---

### 2.3 刷新 Token

```
POST /api/v1/auth/refresh
```

**Request:**

```json
{
  "refreshToken": "dGhpcyBpcyBhIHJlZnJl..."
}
```

**Response 200:**

```json
{
  "code": 0,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...(新)",
    "refreshToken": "bmV3IHJlZnJlc2ggdG9r...(新)",
    "expiresIn": 7200
  },
  "message": "success"
}
```

**Error 401:**

```json
{ "code": 40101, "data": null, "message": "refreshToken已过期，请重新登录" }
```

**说明：**
- 使用 refreshToken 换取新的 accessToken + refreshToken（双刷新）
- refreshToken 过期时，前端需跳转登录页

---

### 2.4 获取用户信息

```
GET /api/v1/user/profile
Authorization: Bearer <accessToken>
```

**Response 200:**

```json
{
  "code": 0,
  "data": {
    "id": "6801234567890abcdef12345",
    "phone": "138****8000",
    "nickname": "小明妈妈",
    "avatar": "https://cdn.ziqu.com/avatars/default.png",
    "privacyAccepted": true,
    "createdAt": "2026-04-21T12:00:00.000Z"
  },
  "message": "success"
}
```

---

### 2.5 更新用户信息

```
PUT /api/v1/user/profile
Authorization: Bearer <accessToken>
```

**Request:**

```json
{
  "nickname": "小趣妈妈",
  "avatar": "https://cdn.ziqu.com/avatars/new.png"
}
```

**Response 200:**

```json
{
  "code": 0,
  "data": {
    "id": "6801234567890abcdef12345",
    "phone": "138****8000",
    "nickname": "小趣妈妈",
    "avatar": "https://cdn.ziqu.com/avatars/new.png",
    "privacyAccepted": true,
    "createdAt": "2026-04-21T12:00:00.000Z"
  },
  "message": "success"
}
```

---

## 三、儿童档案模块

### 3.1 获取儿童列表

```
GET /api/v1/children
Authorization: Bearer <accessToken>
```

**Response 200:**

```json
{
  "code": 0,
  "data": {
    "list": [
      {
        "id": "6801234567890abcdef12350",
        "name": "小趣",
        "avatar": "https://cdn.ziqu.com/children/avatar1.png",
        "gender": "male",
        "birthDate": "2019-06-15",
        "grade": 1,
        "currentLevel": 1,
        "knownCharacterCount": 25,
        "streakDays": 3,
        "totalStars": 48,
        "totalReadingMinutes": 120,
        "isVip": false,
        "vipExpireAt": null
      }
    ]
  },
  "message": "success"
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 儿童ID |
| name | String | 昵称 |
| avatar | String | 头像URL |
| gender | String | 性别：male/female/unknown |
| birthDate | String | 出生日期 (YYYY-MM-DD) |
| grade | Number | 年级：0=学前, 1-6=小学1-6年级 |
| currentLevel | Number | 当前等级 L1-L5 |
| knownCharacterCount | Number | 已识字数量 |
| streakDays | Number | 连续学习天数 |
| totalStars | Number | 总星星数 |
| totalReadingMinutes | Number | 总阅读分钟数 |
| isVip | Boolean | 是否VIP |
| vipExpireAt | String/null | VIP过期时间 |

**说明：**
- 一个家长账号最多创建 3 个儿童档案
- 列表按创建时间排序

---

### 3.2 创建儿童档案

```
POST /api/v1/children
Authorization: Bearer <accessToken>
```

**Request:**

```json
{
  "name": "小趣",
  "gender": "male",
  "birthDate": "2019-06-15",
  "grade": 1
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | String | 是 | 昵称，最长30字 |
| gender | String | 否 | male/female/unknown，默认unknown |
| birthDate | String | 是 | 出生日期 (YYYY-MM-DD) |
| grade | Number | 否 | 年级，默认0（学前） |

**Response 201:**

```json
{
  "code": 0,
  "data": {
    "id": "6801234567890abcdef12350",
    "name": "小趣",
    "avatar": "",
    "gender": "male",
    "birthDate": "2019-06-15",
    "grade": 1,
    "currentLevel": 1,
    "knownCharacterCount": 0,
    "streakDays": 0,
    "totalStars": 0,
    "totalReadingMinutes": 0,
    "isVip": false,
    "vipExpireAt": null
  },
  "message": "success"
}
```

**Error 400:**

```json
{ "code": 40010, "data": null, "message": "昵称不能为空" }
```

```json
{ "code": 40011, "data": null, "message": "出生日期格式不正确" }
```

**Error 403:**

```json
{ "code": 40310, "data": null, "message": "已达到最大儿童档案数量（3个）" }
```

---

### 3.3 获取儿童详情

```
GET /api/v1/children/:id
Authorization: Bearer <accessToken>
```

**Response 200:**

```json
{
  "code": 0,
  "data": {
    "id": "6801234567890abcdef12350",
    "name": "小趣",
    "avatar": "https://cdn.ziqu.com/children/avatar1.png",
    "gender": "male",
    "birthDate": "2019-06-15",
    "grade": 1,
    "currentLevel": 1,
    "knownCharacterCount": 25,
    "streakDays": 3,
    "totalStars": 48,
    "totalReadingMinutes": 120,
    "isVip": false,
    "vipExpireAt": null,
    "lastLearningAt": "2026-04-21T10:30:00.000Z",
    "createdAt": "2026-04-20T08:00:00.000Z"
  },
  "message": "success"
}
```

**Error 404:**

```json
{ "code": 40410, "data": null, "message": "儿童档案不存在" }
```

**Error 403:**

```json
{ "code": 40311, "data": null, "message": "无权访问该儿童档案" }
```

---

### 3.4 更新儿童档案

```
PUT /api/v1/children/:id
Authorization: Bearer <accessToken>
```

**Request:**

```json
{
  "name": "小趣趣",
  "avatar": "https://cdn.ziqu.com/children/new_avatar.png",
  "grade": 2
}
```

**Response 200:**

```json
{
  "code": 0,
  "data": {
    "id": "6801234567890abcdef12350",
    "name": "小趣趣",
    "avatar": "https://cdn.ziqu.com/children/new_avatar.png",
    "gender": "male",
    "birthDate": "2019-06-15",
    "grade": 2,
    "currentLevel": 1,
    "knownCharacterCount": 25,
    "streakDays": 3,
    "totalStars": 48,
    "totalReadingMinutes": 120,
    "isVip": false,
    "vipExpireAt": null
  },
  "message": "success"
}
```

---

### 3.5 删除儿童档案（软删除）

```
DELETE /api/v1/children/:id
Authorization: Bearer <accessToken>
```

**Response 200:**

```json
{
  "code": 0,
  "data": null,
  "message": "删除成功"
}
```

**说明：**
- 软删除，数据保留但 status 变为 archived
- 列表接口不再返回已删除的档案

---

## 四、Token 刷新流程图

```
┌──────────┐                           ┌──────────┐
│  前端APP  │                           │  后端API  │
└─────┬────┘                           └─────┬────┘
      │                                      │
      │  1. 请求API (accessToken)            │
      │─────────────────────────────────────▶│
      │                                      │
      │  2. 返回 401 (Token过期)              │
      │◀─────────────────────────────────────│
      │                                      │
      │  3. POST /auth/refresh (refreshToken)│
      │─────────────────────────────────────▶│
      │                                      │
      │  4. 返回新 accessToken+refreshToken   │
      │◀─────────────────────────────────────│
      │                                      │
      │  5. 用新Token重发原始请求              │
      │─────────────────────────────────────▶│
      │                                      │
      │  6. 正常返回数据                      │
      │◀─────────────────────────────────────│
      │                                      │
      │  ※ refreshToken也过期时               │
      │  → 跳转登录页                         │
```

---

## 五、前端开发建议

### 5.1 Token 存储

```dart
// Flutter 推荐使用 flutter_secure_storage
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

// 存储 Token
await storage.write(key: 'accessToken', value: token);
await storage.write(key: 'refreshToken', value: refreshToken);

// 读取 Token
final accessToken = await storage.read(key: 'accessToken');
```

### 5.2 Dio 拦截器（自动刷新 Token）

```dart
// 建议实现 Dio Interceptor
class AuthInterceptor extends Interceptor {
  @override
  onError(DioException err) async {
    if (err.response?.statusCode == 401) {
      // Token 过期，尝试刷新
      final newToken = await _refreshToken();
      if (newToken != null) {
        // 用新 Token 重发请求
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        return dio.fetch(err.requestOptions);
      } else {
        // refreshToken 也过期，跳转登录
        navigateToLogin();
      }
    }
    return err;
  }
}
```

### 5.3 登录流程建议

```
1. 用户输入手机号
2. 点击「获取验证码」→ POST /auth/sms/send
3. 倒计时60秒
4. 用户输入验证码
5. 点击「登录」→ POST /auth/login
6. 判断 isNewUser:
   - true → 引导创建儿童档案
   - false → 进入首页（选择儿童）
```

---

*文档版本：v1.0*  
*更新日期：2026-04-21*  
*前端可按此文档先行开发，Swagger文档将随代码同步生成*
