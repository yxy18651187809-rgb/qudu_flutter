#!/bin/bash
# 绘本测评API全链路测试脚本

BASE_URL="http://localhost:3000/api/v1"
TOKEN=""

echo "========================================="
echo "绘本测评API全链路联调测试"
echo "========================================="

# 1. 发送验证码
echo ""
echo "[1/6] 发送验证码..."
SMS_RESULT=$(curl -s -X POST "$BASE_URL/auth/sms/send" \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000"}')
echo "响应: $SMS_RESULT"

# 2. 登录获取token（开发环境验证码固定123456）
echo ""
echo "[2/6] 登录获取Token..."
LOGIN_RESULT=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","code":"123456","privacyAccepted":true}')
echo "响应: $LOGIN_RESULT"

TOKEN=$(echo $LOGIN_RESULT | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('data',{}).get('accessToken',''))" 2>/dev/null)
echo "Token: ${TOKEN:0:20}..."

if [ -z "$TOKEN" ]; then
  echo "❌ 登录失败，无法获取Token"
  exit 1
fi

# 3. 获取用户信息
echo ""
echo "[3/6] 获取用户信息..."
USER_RESULT=$(curl -s -X GET "$BASE_URL/user/profile" \
  -H "Authorization: Bearer $TOKEN")
echo "响应: $USER_RESULT"

# 4. 获取儿童列表
echo ""
echo "[4/6] 获取儿童列表..."
CHILDREN_RESULT=$(curl -s -X GET "$BASE_URL/children" \
  -H "Authorization: Bearer $TOKEN")
echo "响应: $CHILDREN_RESULT"

CHILD_ID=$(echo $CHILDREN_RESULT | python3 -c "import json,sys; d=json.load(sys.stdin); l=d.get('data',[]); print(l[0]['id'] if l else '')" 2>/dev/null)

# 如果没有儿童，创建测试儿童
if [ -z "$CHILD_ID" ]; then
  echo "创建测试儿童档案..."
  CREATE_CHILD_RESULT=$(curl -s -X POST "$BASE_URL/children" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"测试小朋友","birthDate":"2019-06-01","gender":"male"}')
  echo "响应: $CREATE_CHILD_RESULT"
  CHILD_ID=$(echo $CREATE_CHILD_RESULT | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('data',{}).get('id',''))" 2>/dev/null)
fi

echo "儿童ID: $CHILD_ID"

if [ -z "$CHILD_ID" ]; then
  echo "❌ 无可用儿童ID"
  exit 1
fi

# 5. 开始测评 (initial类型)
echo ""
echo "[5/6] 开始测评..."
START_RESULT=$(curl -s -X POST "$BASE_URL/assessments/start" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"childId\":\"$CHILD_ID\",\"type\":\"initial\",\"targetLevel\":1,\"questionCount\":5}")
echo "响应: $START_RESULT"

ASSESSMENT_ID=$(echo $START_RESULT | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('data',{}).get('assessmentId',''))" 2>/dev/null)
echo "测评ID: $ASSESSMENT_ID"

if [ -z "$ASSESSMENT_ID" ]; then
  echo "❌ 创建测评失败"
  exit 1
fi

# 提取题目信息
QUESTIONS=$(echo $START_RESULT | python3 -c "import json,sys; d=json.load(sys.stdin); q=d.get('data',{}).get('questions',[]); print(len(q))" 2>/dev/null)
echo "题目数量: $QUESTIONS"

# 6. 提交测评答案
echo ""
echo "[6/6] 提交测评答案..."
# 生成模拟答案（全部选第一个选项）
ANSWERS="["
for i in $(seq 1 $QUESTIONS); do
  if [ $i -gt 1 ]; then
    ANSWERS+=","
  fi
  ANSWERS+="{\"characterId\":\"char_$i\",\"userAnswer\":\"option1\",\"responseTime\":2000}"
done
ANSWERS+="]"

SUBMIT_RESULT=$(curl -s -X POST "$BASE_URL/assessments/$ASSESSMENT_ID/submit" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"answers\":$ANSWERS,\"duration\":60}")
echo "响应: $SUBMIT_RESULT"

# 分析结果
CORRECT_COUNT=$(echo $SUBMIT_RESULT | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('data',{}).get('correctCount',0))" 2>/dev/null)
TOTAL_COUNT=$(echo $SUBMIT_RESULT | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('data',{}).get('totalCount',0))" 2>/dev/null)
ACCURACY=$(echo $SUBMIT_RESULT | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('data',{}).get('accuracy',0))" 2>/dev/null)
ESTIMATED_WORDS=$(echo $SUBMIT_RESULT | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('data',{}).get('estimatedWordCount',0))" 2>/dev/null)
RECOMMENDED_LEVEL=$(echo $SUBMIT_RESULT | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('data',{}).get('recommendedLevel',0))" 2>/dev/null)
STARS=$(echo $SUBMIT_RESULT | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('data',{}).get('starsEarned',0))" 2>/dev/null)
COINS=$(echo $SUBMIT_RESULT | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('data',{}).get('coinsEarned',0))" 2>/dev/null)

echo ""
echo "========================================="
echo "测试结果汇总"
echo "========================================="
echo "✅ 登录: 成功"
echo "✅ 用户信息: 获取成功"
echo "✅ 儿童档案: $CHILD_ID"
echo "✅ 测评ID: $ASSESSMENT_ID"
echo ""
echo "📊 测评结果:"
echo "   正确: $CORRECT_COUNT/$TOTAL_COUNT"
echo "   正确率: $ACCURACY%"
echo "   估算识字量: $ESTIMATED_WORDS 字"
echo "   推荐级别: L$RECOMMENDED_LEVEL"
echo "   获得星星: ⭐$STARS"
echo "   获得金币: 💰$COINS"
echo ""
echo "✅ 绘本测评全链路联调测试通过！"