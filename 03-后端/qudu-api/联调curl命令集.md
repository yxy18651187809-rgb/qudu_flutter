# 字趣阅读 - 联调测试 curl 命令集

> 环境：http://localhost:3000/api/v1
> Mock模式验证码：123456
> 创建时间：2026-04-22

## 使用说明

1. 先启动后端服务：`cd 03-后端/qudu-api && npm run dev`
2. 按顺序执行以下命令（后续命令依赖前面的 Token 和 ID）
3. 变量说明：`$TOKEN` = accessToken, `$CHILD_ID` = 儿童ID, `$BOOK_ID` = 绘本ID

---

## 一、健康检查

```bash
# 服务健康检查
curl -s http://localhost:3000/health | python3 -m json.tool
```

---

## 二、认证模块（3个接口）

### 2.1 发送验证码

```bash
curl -s -X POST http://localhost:3000/api/v1/auth/sms/send \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000"}' | python3 -m json.tool
```

预期响应：
```json
{
  "code": 0,
  "data": {
    "phone": "138****8000",
    "expiresIn": 300
  },
  "message": "success"
}
```

### 2.2 登录（Mock验证码123456）

```bash
curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","code":"123456","privacyAccepted":true}' | python3 -m json.tool
```

预期响应：
```json
{
  "code": 0,
  "data": {
    "accessToken": "eyJhbG...",
    "refreshToken": "eyJhbG...",
    "isNewUser": false,
    "user": {
      "id": "...",
      "phone": "138****8000",
      "nickname": "测试用户",
      "avatar": "..."
    }
  },
  "message": "success"
}
```

> ⚠️ 复制 accessToken 值，后续请求用到

### 2.3 刷新Token

```bash
# 替换 $REFRESH_TOKEN 为登录返回的 refreshToken
curl -s -X POST http://localhost:3000/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken":"$REFRESH_TOKEN"}' | python3 -m json.tool
```

---

## 三、用户模块（2个接口）

### 3.1 获取用户信息

```bash
curl -s http://localhost:3000/api/v1/user/profile \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```

### 3.2 更新用户信息

```bash
curl -s -X PUT http://localhost:3000/api/v1/user/profile \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"nickname":"小明妈妈"}' | python3 -m json.tool
```

---

## 四、儿童档案模块（5个接口）

### 4.1 获取儿童列表

```bash
curl -s http://localhost:3000/api/v1/children \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```

### 4.2 创建儿童档案

```bash
curl -s -X POST http://localhost:3000/api/v1/children \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"小明","birthDate":"2019-06-15","gender":"male"}' | python3 -m json.tool
```

预期响应：
```json
{
  "code": 0,
  "data": {
    "id": "...",
    "name": "小明",
    "birthDate": "2019-06-15",
    "gender": "male",
    "level": 1,
    "totalStars": 0,
    "totalCoins": 0,
    "streakDays": 0
  },
  "message": "success"
}
```

> ⚠️ 复制儿童 id 值，后续请求用到

### 4.3 获取儿童详情

```bash
curl -s http://localhost:3000/api/v1/children/$CHILD_ID \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```

### 4.4 更新儿童档案

```bash
curl -s -X PUT http://localhost:3000/api/v1/children/$CHILD_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"小明","gender":"male"}' | python3 -m json.tool
```

### 4.5 删除儿童档案（软删除）

```bash
curl -s -X DELETE http://localhost:3000/api/v1/children/$CHILD_ID \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```

---

## 五、绘本模块（5个接口，无需Token也可访问）

### 5.1 获取绘本列表

```bash
# 全部绘本
curl -s "http://localhost:3000/api/v1/books" | python3 -m json.tool

# 按级别筛选
curl -s "http://localhost:3000/api/v1/books?level=1" | python3 -m json.tool

# 按主题筛选
curl -s "http://localhost:3000/api/v1/books?theme=身体认知" | python3 -m json.tool
```

### 5.2 获取绘本详情（含页面）

```bash
# 替换 $BOOK_ID 为列表返回的绘本 id
curl -s "http://localhost:3000/api/v1/books/$BOOK_ID" | python3 -m json.tool

# 带儿童ID，额外返回新字掌握进度
curl -s "http://localhost:3000/api/v1/books/$BOOK_ID?childId=$CHILD_ID" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```

### 5.3 获取免费绘本

```bash
curl -s "http://localhost:3000/api/v1/books/free" | python3 -m json.tool
```

### 5.4 智能推荐绘本

```bash
# 热门推荐（无childId）
curl -s "http://localhost:3000/api/v1/books/recommended" | python3 -m json.tool

# 个性化推荐（带childId需登录）
curl -s "http://localhost:3000/api/v1/books/recommended?childId=$CHILD_ID" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```

### 5.5 获取主题列表

```bash
curl -s "http://localhost:3000/api/v1/books/themes" | python3 -m json.tool
```

---

## 六、识字测评模块（4个接口）

### 6.1 开始测评

```bash
curl -s -X POST http://localhost:3000/api/v1/assessments/start \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"childId":"$CHILD_ID","type":"initial","questionCount":10}' | python3 -m json.tool
```

预期响应（含题目，无正确答案）：
```json
{
  "code": 0,
  "data": {
    "assessmentId": "...",
    "type": "initial",
    "status": "in_progress",
    "questions": [
      {
        "characterId": "...",
        "character": "人",
        "questionType": "recognize",
        "options": ["rén", "bā", "dà", "xiǎo"]
      }
    ],
    "startedAt": "..."
  }
}
```

> ⚠️ 复制 assessmentId

### 6.2 提交测评答案

```bash
# 替换 $ASSESSMENT_ID 和 characterId
curl -s -X POST http://localhost:3000/api/v1/assessments/$ASSESSMENT_ID/submit \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "answers": [
      {"characterId":"$CHAR_ID_1","userAnswer":"rén","responseTime":1500},
      {"characterId":"$CHAR_ID_2","userAnswer":"dà","responseTime":2000}
    ],
    "duration": 120
  }' | python3 -m json.tool
```

预期响应（含识字量估算和推荐级别）：
```json
{
  "code": 0,
  "data": {
    "assessmentId": "...",
    "status": "completed",
    "correctCount": 1,
    "totalCount": 2,
    "accuracy": 50,
    "estimatedWordCount": 80,
    "recommendedLevel": 1,
    "starsEarned": 1,
    "coinsEarned": 3
  }
}
```

### 6.3 获取测评结果

```bash
curl -s http://localhost:3000/api/v1/assessments/$ASSESSMENT_ID \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```

### 6.4 获取测评历史

```bash
curl -s "http://localhost:3000/api/v1/assessments/history/$CHILD_ID?page=1&pageSize=10" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```

---

## 七、学习记录模块（3个接口）

### 7.1 记录学习数据

```bash
# 记录阅读
curl -s -X POST http://localhost:3000/api/v1/learning/record \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "childId":"$CHILD_ID",
    "type":"reading",
    "bookId":"$BOOK_ID",
    "duration": 300
  }' | python3 -m json.tool

# 记录识字学习
curl -s -X POST http://localhost:3000/api/v1/learning/record \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "childId":"$CHILD_ID",
    "type":"word_study",
    "characters": [
      {"characterId":"$CHAR_ID","character":"人","result":"correct","responseTime":1200},
      {"characterId":"$CHAR_ID2","character":"口","result":"wrong","responseTime":3000}
    ],
    "duration": 60
  }' | python3 -m json.tool
```

### 7.2 获取学习历史

```bash
curl -s "http://localhost:3000/api/v1/learning/history/$CHILD_ID?page=1&pageSize=10" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```

### 7.3 获取学习统计

```bash
curl -s "http://localhost:3000/api/v1/learning/stats/$CHILD_ID" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```

---

## 八、联调全链路脚本（一键测试）

```bash
#!/bin/bash
# 全链路联调测试脚本
# 前提：MongoDB+Redis已启动，npm run seed已执行

BASE="http://localhost:3000/api/v1"
PHONE="13800138000"
CODE="123456"

echo "=== 1. 健康检查 ==="
curl -s http://localhost:3000/health | python3 -m json.tool

echo -e "\n=== 2. 发送验证码 ==="
curl -s -X POST "$BASE/auth/sms/send" \
  -H "Content-Type: application/json" \
  -d "{\"phone\":\"$PHONE\"}" | python3 -m json.tool

echo -e "\n=== 3. 登录 ==="
LOGIN_RESP=$(curl -s -X POST "$BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"phone\":\"$PHONE\",\"code\":\"$CODE\",\"privacyAccepted\":true}")
echo $LOGIN_RESP | python3 -m json.tool

TOKEN=$(echo $LOGIN_RESP | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['accessToken'])")
echo "Token: ${TOKEN:0:20}..."

echo -e "\n=== 4. 获取用户信息 ==="
curl -s "$BASE/user/profile" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

echo -e "\n=== 5. 创建儿童档案 ==="
CHILD_RESP=$(curl -s -X POST "$BASE/children" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"小明","birthDate":"2019-06-15","gender":"male"}')
echo $CHILD_RESP | python3 -m json.tool

CHILD_ID=$(echo $CHILD_RESP | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])")
echo "Child ID: $CHILD_ID"

echo -e "\n=== 6. 获取绘本列表 ==="
BOOKS_RESP=$(curl -s "$BASE/books?level=1")
echo $BOOKS_RESP | python3 -m json.tool

BOOK_ID=$(echo $BOOKS_RESP | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['list'][0]['id'])")
echo "Book ID: $BOOK_ID"

echo -e "\n=== 7. 获取绘本详情 ==="
curl -s "$BASE/books/$BOOK_ID?childId=$CHILD_ID" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

echo -e "\n=== 8. 开始测评 ==="
ASSESS_RESP=$(curl -s -X POST "$BASE/assessments/start" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"childId\":\"$CHILD_ID\",\"type\":\"initial\",\"questionCount\":5}")
echo $ASSESS_RESP | python3 -m json.tool

ASSESS_ID=$(echo $ASSESS_RESP | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['assessmentId'])")
echo "Assessment ID: $ASSESS_ID"

echo -e "\n=== 9. 获取学习统计 ==="
curl -s "$BASE/learning/stats/$CHILD_ID" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

echo -e "\n✅ 全链路联调测试完成！"
```

---

## 九、Swagger 文档

- Swagger UI: http://localhost:3000/api-docs
- Swagger JSON: http://localhost:3000/api-docs.json

---

*文档版本：v1.0*
*创建日期：2026-04-22*
*维护者：后端负责人*
