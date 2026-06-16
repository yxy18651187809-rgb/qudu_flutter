# Phase 1.1 前端联调对接文档

> 后端状态：✅ 全部就绪 | 日期：2026-06-14 | 维护：后端负责人

---

## 一、环境信息

| 项目 | 值 |
|------|-----|
| 后端地址 | `http://localhost:3001` |
| Swagger文档 | `http://localhost:3001/api-docs` |
| PM2监控 | `pm2 logs qudu-api` |
| 测试账号 | `13800138000` / 验证码 `123456` |
| MongoDB | localhost:27017, qudu:qudu_dev_2026 |

---

## 二、联调前置检查

```bash
# 1. 确认后端在线
curl http://localhost:3001/api/v1/characters?level=1

# 2. 确认数据库有数据
curl -s "http://localhost:3001/api/v1/characters?pageSize=1" | json_pp | grep total

# 3. 确认静态资源可访问
curl -I http://localhost:3001/audio/books/L1_book_01_p1.mp3
```

---

## 三、核心API 端到端联调流程

### Step 1: 发送验证码
```bash
curl -X POST http://localhost:3001/api/v1/auth/sms/send \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000"}'
```
预期：`{"code":0, "data":{"phone":"13800138000","expireIn":300}}`

### Step 2: 登录获取Token
```bash
curl -X POST http://localhost:3001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","code":"123456"}'
```
预期：`{"code":0, "data":{"accessToken":"...","refreshToken":"...","user":{...}}}`

### Step 3: 创建儿童账号（需Auth Header）
```bash
TOKEN="<从Step 2获取>"
curl -X POST http://localhost:3001/api/v1/children \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"测试宝宝","birthDate":"2021-06-01","gender":"male"}'
```
预期返回 childId（记下用于Step 4）

### Step 4: 学习报告 API
```bash
CHILD_ID="<从Step 3获取>"
curl "http://localhost:3001/api/v1/learning-report/$CHILD_ID?period=weekly" \
  -H "Authorization: Bearer $TOKEN"
```
预期：`{"code":0, "data":{"period":"weekly","totalMinutes":0,...}}`

### Step 5: 家长监控 API
```bash
curl "http://localhost:3001/api/v1/parent-monitoring/<parentId>" \
  -H "Authorization: Bearer $TOKEN"
```
parentId 从 Step 2 登录响应 `user.parentId` 获取。

---

## 四、API 接口速查表

### 识字相关
| 方法 | 路径 | 说明 | 关键参数 |
|------|------|------|---------|
| GET | `/api/v1/characters` | 字卡列表 | `?level=1~5&pageSize=100` |
| GET | `/api/v1/characters/:id` | 单字详情 | |
| GET | `/api/v1/books` | 绘本列表 | `?level=1~5&status=online` |
| GET | `/api/v1/books/:id` | 绘本详情+页面 | |
| GET | `/api/v1/books/:id/tts` | 绘本朗读音频 | `?page=1`（可选，单页） |
| GET | `/api/v1/tts/character/:char` | 汉字发音 | `:char=一` |

### 学习相关（需Auth）
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/v1/learning-report/:childId` | 学习报告 `?period=weekly/monthly` |
| GET | `/api/v1/learning-report/:childId/characters-trend` | 汉字学习趋势 |
| POST | `/api/v1/learning-record` | 记录学习行为 |
| GET | `/api/v1/assessment/start` | 开始测评 |
| POST | `/api/v1/assessment/:id/submit` | 提交测评 |
| GET | `/api/v1/assessment/history/:childId` | 测评历史 |
| GET | `/api/v1/assessment/stats/:childId` | 测评统计 |

### 家长中心（需Auth）
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/v1/parent-monitoring/:parentId` | 家长监控总览 |
| PUT | `/api/v1/parent-monitoring/:parentId/alert-settings` | 提醒设置 |
| PUT | `/api/v1/parent-monitoring/:parentId/child/:childId/thresholds` | 学习阈值 |
| GET | `/api/v1/children` | 儿童列表 |
| POST | `/api/v1/children` | 新增儿童 |
| PUT | `/api/v1/children/:id` | 编辑儿童 |
| DELETE | `/api/v1/children/:id` | 删除儿童 |

### 用户认证
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/v1/auth/sms/send` | 发送短信验证码 |
| POST | `/api/v1/auth/login` | 手机验证码登录 |
| POST | `/api/v1/auth/refresh` | 刷新Token |
| POST | `/api/v1/auth/wechat-login` | 微信登录 |
| GET | `/api/v1/auth/profile` | 获取用户信息（需Auth） |
| PUT | `/api/v1/auth/profile` | 更新用户信息（需Auth） |
| DELETE | `/api/v1/auth/account` | **账号注销**（需Auth，操作不可逆） |

### 账号注销（🆕 6/14新增）
```
DELETE /api/v1/auth/account
Authorization: Bearer <accessToken>
```
**Response 200:**
```json
{
  "code": 0,
  "data": {
    "deletedAt": "2026-06-14T12:23:55.999Z",
    "summary": {
      "wordMastery": 0,
      "learningRecords": 0,
      "learningReports": 0,
      "assessments": 0,
      "children": 1,
      "parentMonitoring": 0
    }
  },
  "message": "账号已注销"
}
```
**行为说明：**
- 级联删除：User → 所有Children → 每条Child的WordMastery/LearningRecord/LearningReport/Assessment → ParentMonitoring
- SMS验证码缓存同步清除
- **操作不可逆**，前端应在用户二次确认后调用
- 注销成功后：清除本地Token → 跳转登录页
- ⚠️ 注销后accessToken仍短暂有效（JWT无状态），但/api/auth/refresh会因user不存在返回401
- 重新使用同一手机号注册 → 视为全新用户

---

## 五、Flutter 端对接要点

### 5.1 Base URL 配置
```dart
// 开发环境
static const String baseUrl = 'http://localhost:3001/api/v1';

// iOS模拟器用
// static const String baseUrl = 'http://127.0.0.1:3001/api/v1';
```

### 5.2 Token 管理
- 登录成功后将 `accessToken` 存入 SharedPreferences
- 所有请求带 `Authorization: Bearer <accessToken>`
- accessToken 过期(2h)后自动用 refreshToken 刷新
- 注意：后端 `ApiClient` 已实现 401 自动刷新 + 请求队列

### 5.3 level 参数注意
- `characters?level=` 参数使用**数字 1-5**，不是 "L1"-"L5"
- 例如：`GET /api/v1/characters?level=1` 查 L1 字库

### 5.4 音频路径
- 字卡发音：`/audio/L1_301_word.mp3` 格式，或通过 TTS API 动态获取
- 绘本朗读：`/audio/books/L1_book_01_p1.mp3` 格式（L1 10本 + L2 10本）
- TTS API 返回完整URL，前端直接播放即可

### 5.5 绘本图片
- 图片路径由 `/api/v1/books/:id` 返回的 `pages[].imageUrl` 字段提供
- 封面图：800×1000 px（4:5 竖版）
- 内页图：800×1000 px（4:5 竖版），使用 `BoxFit.contain`

---

## 六、已知差异 / 注意事项

1. **level 参数为数字**：API `?level=1`（非 "L1"），`characters?level=1` 返回 L1 301字
2. **ObjectId格式**：API 返回的 `_id` 已在 Model 层转为 `id`（toJSON transform），前端统一读取 `id`
3. **bookId 格式**：`L1_book_01` / `L2_book_01` 等
4. **微信登录**：依赖 fluwx SDK，需微信开放平台 AppID
5. **CORS**：当前允许所有来源（开发模式），生产需收窄为 `app.ziqu.com`
6. **parentId**：登录后从 `user.parentId` 获取，非硬编码

---

## 七、一键测试脚本

```bash
#!/bin/bash
# 保存为 test_api.sh，运行：bash test_api.sh
BASE="http://localhost:3001/api/v1"

echo "=== 1. 发送验证码 ==="
curl -s -X POST "$BASE/auth/sms/send" -H "Content-Type: application/json" -d '{"phone":"13800138000"}' | json_pp

echo -e "\n=== 2. 登录 ==="
RESP=$(curl -s -X POST "$BASE/auth/login" -H "Content-Type: application/json" -d '{"phone":"13800138000","code":"123456"}')
echo "$RESP" | json_pp
TOKEN=$(echo "$RESP" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)

echo -e "\n=== 3. 字库数据 ==="
for lvl in 1 2 3 4 5; do
  curl -s "$BASE/characters?level=$lvl&pageSize=1" | grep -o '"total":[0-9]*'
done

echo -e "\n=== 4. 绘本列表 ==="
curl -s "$BASE/books" | grep -o '"total":[0-9]*'

echo -e "\n=== 5. 音频检查 ==="
curl -sI http://localhost:3001/audio/books/L1_book_01_p1.mp3 | head -3

echo -e "\n=== 6. 账号注销测试（需要先登录获取Token） ==="
curl -s -X DELETE "$BASE/auth/account" -H "Authorization: Bearer $TOKEN"
# 预期: {"code":0,"data":{"deletedAt":"...","summary":{...}},"message":"账号已注销"}
```

---

*文档版本：v1.1 | 更新日期：2026-06-14（新增账号注销接口）*
