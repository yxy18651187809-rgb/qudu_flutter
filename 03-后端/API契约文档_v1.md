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
  "code": "123456"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| phone | String | 是 | 手机号 |
| code | String | 是 | 6位验证码（body参数名，非smsCode） |

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

## 六、绘本模块

### 6.1 获取绘本列表

```
GET /books
```

**Query 参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| level | string | 否 | 级别筛选，逗号分隔（如 "1,2"） |
| theme | string | 否 | 主题筛选 |
| isFree | boolean | 否 | 是否免费 |
| sort | string | 否 | 排序：sortOrder(默认)/popular/newest/rating |
| page | number | 否 | 页码，默认1 |
| pageSize | number | 否 | 每页条数，默认20 |

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "list": [
      {
        "_id": "6800...",
        "title": "我的身体",
        "cover": "",
        "description": "认识身体、学会爱护自己",
        "level": 1,
        "theme": "身体认知",
        "tags": ["身体", "认知", "自我"],
        "protagonist": {
          "name": "小明",
          "description": "小女孩，扎两个小辫子"
        },
        "newWordCount": 15,
        "pageCount": 10,
        "totalCharacters": 100,
        "estimatedMinutes": 5,
        "isFree": true,
        "readCount": 0,
        "favoriteCount": 0,
        "rating": 5,
        "sortOrder": 1,
        "status": "online"
      }
    ],
    "pagination": {
      "page": 1,
      "pageSize": 20,
      "total": 2,
      "totalPages": 1
    }
  },
  "message": "success"
}
```

---

### 6.2 获取绘本详情（含页面）

```
GET /books/:id
```

**Query 参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| childId | string | 否 | 儿童ID，传入后返回新字掌握进度 |

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "_id": "6800...",
    "title": "我的身体",
    "level": 1,
    "theme": "身体认知",
    "newWords": ["6800...", "6800..."],
    "newWordCount": 15,
    "reviewWords": ["6800..."],
    "pageCount": 10,
    "exercises": [
      {
        "type": "image_match",
        "question": "看看图片，选出正确的汉字",
        "instruction": "手的图片→手、头的图片→头、嘴巴的图片→口"
      }
    ],
    "pages": [
      {
        "_id": "6800...",
        "pageNumber": 1,
        "text": "我是小明。",
        "pinyin": "[wǒ shì xiǎo míng]",
        "image": "",
        "imageDescription": "小主人公小明对着镜子，开心地指着自己",
        "wordAnnotations": [
          {
            "characterId": "6800...",
            "character": "我",
            "isNewWord": true,
            "highlightStyle": "both"
          },
          {
            "characterId": "6800...",
            "character": "小",
            "isNewWord": true,
            "highlightStyle": "both"
          }
        ],
        "teachingNote": "认识"我"是自己的称呼，"小"表示可爱的意思"
      }
    ],
    "newWordProgress": [
      { "characterId": "6800...", "mastered": false },
      { "characterId": "6800...", "mastered": true }
    ],
    "masteredCount": 3
  },
  "message": "success"
}
```

---

### 6.3 智能推荐绘本

```
GET /books/recommended
```

**Query 参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| childId | string | 否 | 儿童ID，传入后个性化推荐 |
| limit | number | 否 | 返回数量，默认6 |

**推荐逻辑：**
- 无childId → 返回热门绘本
- 有childId → 基于当前级别和新字掌握率推荐
  - 优先：覆盖率30%-70%（有挑战但不太难）
  - 其次：覆盖率<30%（全新挑战）
  - 最后：覆盖率>70%（复习巩固）
- 不足时补充相邻级别

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "list": [
      {
        "_id": "6800...",
        "title": "我的身体",
        "level": 1,
        "newWordCount": 15,
        "newWordMasteryRate": 0.2,
        "masteredNewWords": 3,
        "totalNewWords": 15,
        "isFree": true
      }
    ],
    "childLevel": 1,
    "reason": "基于L1级别推荐"
  },
  "message": "success"
}
```

---

### 6.4 获取免费绘本

```
GET /books/free
```

**Query 参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| level | number | 否 | 级别筛选 |
| page | number | 否 | 页码，默认1 |
| pageSize | number | 否 | 每页条数，默认20 |

---

### 6.5 获取主题列表

```
GET /books/themes
```

**响应示例：**

```json
{
  "code": 0,
  "data": [
    { "theme": "身体认知", "count": 1 },
    { "theme": "日常作息", "count": 1 }
  ],
  "message": "success"
}
```

---

*文档版本：v1.2*  
*更新日期：2026-04-21*  
*v1.1 新增：第六章 绘本模块 API（6.1-6.5）*  
*v1.2 新增：第七章 识字测评 API、第八章 学习记录 API*  
*全量接口：认证(3) + 儿童档案(5) + 绘本(5) + 测评(4) + 学习(3) = 20个*  
*前端可按此文档先行开发，Swagger文档将随代码同步生成*

---

## 七、识字测评模块

### 7.1 开始测评

```
POST /assessments/start
```

**请求体：**

```json
{
  "childId": "6800...",
  "type": "initial",
  "targetLevel": 1,
  "questionCount": 20
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| childId | string | 是 | 儿童ID |
| type | string | 否 | initial(默认)/review/level_test |
| targetLevel | number | 否 | 目标级别，默认取儿童当前级别 |
| questionCount | number | 否 | 题目数量，默认20 |

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "assessmentId": "6800...",
    "type": "initial",
    "status": "in_progress",
    "questions": [
      {
        "characterId": "6800...",
        "character": "人",
        "questionType": "recognize",
        "options": ["rén", "bā", "dà", "xiǎo"]
      },
      {
        "characterId": "6800...",
        "character": "口",
        "questionType": "pinyin_match",
        "options": ["口", "大", "小", "人"]
      }
    ],
    "startedAt": "2026-04-22T10:00:00.000Z"
  },
  "message": "success"
}
```

**说明：**
- 如有进行中测评，直接返回已有测评
- `questionType` 三种：recognize(看字选拼音)、pinyin_match(看拼音选字)、meaning_select(选意思)
- 响应不包含 `correctAnswer`，防作弊

---

### 7.2 提交测评答案

```
POST /assessments/:id/submit
```

**请求体：**

```json
{
  "answers": [
    { "characterId": "6800...", "userAnswer": "rén", "responseTime": 2300 },
    { "characterId": "6800...", "userAnswer": "口", "responseTime": 1800 }
  ],
  "duration": 180
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| answers | array | 是 | 答案列表 |
| answers[].characterId | string | 是 | 汉字ID |
| answers[].userAnswer | string | 是 | 用户答案 |
| answers[].responseTime | number | 否 | 响应时间(ms) |
| duration | number | 否 | 测评总时长(秒) |

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "assessmentId": "6800...",
    "status": "completed",
    "correctCount": 15,
    "totalCount": 20,
    "accuracy": 75,
    "estimatedWordCount": 120,
    "recommendedLevel": 1,
    "levelResults": [
      { "level": 1, "testedCount": 20, "correctCount": 15, "accuracy": 75 }
    ],
    "starsEarned": 10,
    "coinsEarned": 30,
    "duration": 180
  },
  "message": "success"
}
```

**说明：**
- 提交后自动更新儿童级别、汉字掌握度（遗忘曲线）、学习记录
- 识字量估算基于各级别正确率加权计算
- 奖励：每题正确1星（最多10星），每题3币（最多30币）

---

### 7.3 获取测评结果

```
GET /assessments/:id
```

**响应：** 返回完整测评记录（含题目详情和正确答案）

---

### 7.4 获取测评历史

```
GET /assessments/history/:childId
```

**Query 参数：** page, pageSize

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "list": [
      {
        "id": "6800...",
        "type": "initial",
        "status": "completed",
        "correctCount": 15,
        "totalCount": 20,
        "accuracy": 75,
        "estimatedWordCount": 120,
        "recommendedLevel": 1,
        "startedAt": "2026-04-22T10:00:00.000Z",
        "completedAt": "2026-04-22T10:03:00.000Z",
        "duration": 180
      }
    ],
    "pagination": { "page": 1, "pageSize": 10, "total": 3, "totalPages": 1 }
  }
}
```

---

## 八、学习记录模块

### 8.1 记录学习数据

```
POST /learning/record
```

**请求体：**

```json
{
  "childId": "6800...",
  "type": "reading",
  "subtype": "book_complete",
  "bookId": "6800...",
  "characters": [
    { "characterId": "6800...", "character": "人", "result": "correct", "responseTime": 1500 },
    { "characterId": "6800...", "character": "口", "result": "wrong", "responseTime": 3000 }
  ],
  "duration": 300,
  "startTime": "2026-04-22T10:00:00.000Z",
  "endTime": "2026-04-22T10:05:00.000Z"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| childId | string | 是 | 儿童ID |
| type | string | 是 | assessment/reading/word_study/review/game |
| subtype | string | 否 | 细分类型 |
| bookId | string | 否 | 绘本ID（阅读类型时） |
| characters | array | 否 | 汉字学习结果 |
| duration | number | 否 | 学习时长(秒) |
| startTime | string | 否 | 开始时间 |
| endTime | string | 否 | 结束时间 |

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "recordId": "6800...",
    "starsEarned": 2,
    "coinsEarned": 5,
    "correctCount": 1,
    "totalCount": 2,
    "accuracy": 50
  }
}
```

**奖励规则：**
- reading: 2星5币（完整阅读绘本）
- word_study: 每对1字1星，最多5星；每字2币
- review: 每对1字1星，最多3星；每字1币
- game: 1星2币

---

### 8.2 获取学习历史

```
GET /learning/history/:childId
```

**Query 参数：** type, page, pageSize

---

### 8.3 获取学习统计

```
GET /learning/stats/:childId
```

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "overview": {
      "totalRecords": 25,
      "totalMinutes": 120,
      "totalStars": 45,
      "streakDays": 3,
      "currentLevel": 1
    },
    "today": {
      "records": 2,
      "minutes": 15,
      "stars": 5
    },
    "mastery": {
      "new": 200,
      "learning": 30,
      "reviewing": 15,
      "mastered": 5,
      "dueReview": 8
    },
    "weeklyTrend": [
      { "_id": "2026-04-16", "count": 3, "minutes": 15, "stars": 8 },
      { "_id": "2026-04-17", "count": 5, "minutes": 25, "stars": 12 }
    ]
  }
}
```

**mastery 字段说明：**
- new: 未学过的字
- learning: 正在学习（掌握度<40%）
- reviewing: 复习中（掌握度40%-80%）
- mastered: 已掌握（掌握度>80%且间隔≥6天）
- dueReview: 今日待复习（下次复习时间已到）
