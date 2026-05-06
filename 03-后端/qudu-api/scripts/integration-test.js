#!/usr/bin/env node

/**
 * 字趣阅读 API 集成测试脚本
 * 
 * 使用方式：
 *   node scripts/integration-test.js [BASE_URL]
 * 
 * 默认 BASE_URL: http://localhost:3000/api/v1
 * 
 * 前置条件：
 *   1. MongoDB + Redis 已启动
 *   2. npm run seed 已执行
 *   3. npm run dev 已启动服务
 * 
 * 测试流程：
 *   发验证码 → 登录 → 获取用户信息 → 创建儿童 → 绘本列表 → 绘本详情 → 推荐绘本 → 开始测评 → 提交测评 → 记录学习 → 学习统计
 */

const BASE_URL = process.argv[2] || 'http://localhost:3000/api/v1';
const TEST_PHONE = '13800138000';
const MOCK_CODE = '123456';  // config.sms.mockCode

let accessToken = '';
let refreshToken = '';
let childId = '';
let assessmentId = '';
let passed = 0;
let failed = 0;
let errors = [];

// ===== 工具函数 =====

async function request(method, path, body = null, token = null) {
  const url = `${BASE_URL}${path}`;
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const options = { method, headers };
  if (body) options.body = JSON.stringify(body);

  try {
    const res = await fetch(url, options);
    const data = await res.json();
    return { status: res.status, data };
  } catch (err) {
    return { status: 0, data: null, error: err.message };
  }
}

function assert(name, condition, detail = '') {
  if (condition) {
    console.log(`  ✅ ${name}`);
    passed++;
  } else {
    console.log(`  ❌ ${name} ${detail}`);
    failed++;
    errors.push({ name, detail });
  }
}

// ===== 测试用例 =====

async function testHealthCheck() {
  console.log('\n🔍 健康检查');
  const res = await request('GET', '/../../health');
  assert('服务运行', res.status === 200, `status=${res.status}`);
  if (res.data) {
    assert('MongoDB连接', res.data.mongodb === 'connected', `mongodb=${res.data?.mongodb}`);
  }
}

async function testSendSmsCode() {
  console.log('\n📱 发送验证码');
  const res = await request('POST', '/auth/sms/send', { phone: TEST_PHONE });
  assert('发送验证码', res.status === 200, `status=${res.status}, code=${res.data?.code}`);
}

async function testLogin() {
  console.log('\n🔑 登录');
  const res = await request('POST', '/auth/login', { phone: TEST_PHONE, code: MOCK_CODE });
  assert('登录成功', res.status === 200, `status=${res.status}`);
  assert('返回accessToken', !!res.data?.data?.accessToken, 'missing accessToken');
  assert('返回refreshToken', !!res.data?.data?.refreshToken, 'missing refreshToken');
  
  accessToken = res.data?.data?.accessToken || '';
  refreshToken = res.data?.data?.refreshToken || '';
}

async function testRefreshToken() {
  console.log('\n🔄 刷新Token');
  const res = await request('POST', '/auth/refresh', { refreshToken });
  assert('刷新成功', res.status === 200, `status=${res.status}`);
  if (res.data?.data?.accessToken) {
    accessToken = res.data.data.accessToken;
  }
}

async function testGetProfile() {
  console.log('\n👤 获取用户信息');
  const res = await request('GET', '/user/profile', null, accessToken);
  assert('获取成功', res.status === 200, `status=${res.status}`);
  assert('包含手机号', res.data?.data?.phone === TEST_PHONE, `phone=${res.data?.data?.phone}`);
}

async function testUpdateProfile() {
  console.log('\n✏️ 更新用户信息');
  const res = await request('PUT', '/user/profile', { nickname: '集成测试用户' }, accessToken);
  assert('更新成功', res.status === 200, `status=${res.status}`);
}

async function testCreateChild() {
  console.log('\n👶 创建儿童档案');
  const res = await request('POST', '/children', {
    name: '测试宝贝',
    birthDate: '2020-06-15',
    gender: 'female'
  }, accessToken);
  assert('创建成功', res.status === 201, `status=${res.status}`);
  assert('返回儿童ID', !!res.data?.data?.id, 'missing child id');
  childId = res.data?.data?.id || '';
}

async function testGetChildren() {
  console.log('\n📋 获取儿童列表');
  const res = await request('GET', '/children', null, accessToken);
  assert('获取成功', res.status === 200, `status=${res.status}`);
  assert('列表非空', Array.isArray(res.data?.data) && res.data.data.length > 0, 'empty list');
}

async function testGetChildDetail() {
  console.log('\n🔍 获取儿童详情');
  const res = await request('GET', `/children/${childId}`, null, accessToken);
  assert('获取成功', res.status === 200, `status=${res.status}`);
  assert('名字匹配', res.data?.data?.name === '测试宝贝', `name=${res.data?.data?.name}`);
}

async function testUpdateChild() {
  console.log('\n✏️ 更新儿童档案');
  const res = await request('PUT', `/children/${childId}`, { name: '测试宝贝V2' }, accessToken);
  assert('更新成功', res.status === 200, `status=${res.status}`);
}

async function testGetBooks() {
  console.log('\n📚 获取绘本列表');
  const res = await request('GET', '/books', null, accessToken);
  assert('获取成功', res.status === 200, `status=${res.status}`);
  assert('列表非空', Array.isArray(res.data?.data) && res.data.data.length > 0, 'empty list');
  
  // 检查是否有3本绘本
  const books = res.data?.data || [];
  assert('至少3本绘本', books.length >= 3, `count=${books.length}`);
}

async function testGetBookDetail() {
  console.log('\n📖 获取绘本详情');
  // 先获取绘本列表拿到ID
  const listRes = await request('GET', '/books', null, accessToken);
  const books = listRes.data?.data || [];
  if (books.length === 0) {
    assert('获取绘本详情', false, 'no books available');
    return;
  }
  
  const bookId = books[0].id;
  const res = await request('GET', `/books/${bookId}`, null, accessToken);
  assert('获取成功', res.status === 200, `status=${res.status}`);
  assert('包含页面数据', Array.isArray(res.data?.data?.pages), 'missing pages');
  assert('包含新字', Array.isArray(res.data?.data?.newWords), 'missing newWords');
}

async function testRecommendedBooks() {
  console.log('\n🎯 推荐绘本');
  const res = await request('GET', `/books/recommended?childId=${childId}`, null, accessToken);
  assert('推荐成功', res.status === 200, `status=${res.status}`);
}

async function testFreeBooks() {
  console.log('\n🆓 免费绘本');
  const res = await request('GET', '/books/free', null, accessToken);
  assert('获取成功', res.status === 200, `status=${res.status}`);
}

async function testBookThemes() {
  console.log('\n🎨 绘本主题');
  const res = await request('GET', '/books/themes', null, accessToken);
  assert('获取成功', res.status === 200, `status=${res.status}`);
}

async function testStartAssessment() {
  console.log('\n📝 开始测评');
  const res = await request('POST', '/assessments/start', { childId }, accessToken);
  assert('开始成功', res.status === 200 || res.status === 201, `status=${res.status}`);
  assert('返回测评ID', !!res.data?.data?.id || !!res.data?.data?._id, 'missing assessment id');
  assessmentId = res.data?.data?.id || res.data?.data?._id || '';
}

async function testSubmitAssessment() {
  console.log('\n✅ 提交测评答案');
  if (!assessmentId) {
    assert('提交测评', false, 'no assessmentId');
    return;
  }
  
  const res = await request('POST', `/assessments/${assessmentId}/submit`, {
    answers: [
      { questionIndex: 0, isCorrect: true },
      { questionIndex: 1, isCorrect: false }
    ]
  }, accessToken);
  assert('提交成功', res.status === 200, `status=${res.status}`);
}

async function testGetAssessment() {
  console.log('\n📊 获取测评结果');
  if (!assessmentId) {
    assert('获取测评', false, 'no assessmentId');
    return;
  }
  
  const res = await request('GET', `/assessments/${assessmentId}`, null, accessToken);
  assert('获取成功', res.status === 200, `status=${res.status}`);
}

async function testAssessmentHistory() {
  console.log('\n📋 测评历史');
  const res = await request('GET', `/assessments/history/${childId}`, null, accessToken);
  assert('获取成功', res.status === 200, `status=${res.status}`);
}

async function testRecordLearning() {
  console.log('\n📝 记录学习数据');
  const res = await request('POST', '/learning/record', {
    childId,
    bookId: 'test_book_id',
    type: 'read',
    duration: 120,
    charactersLearned: ['人', '口', '手']
  }, accessToken);
  assert('记录成功', res.status === 200 || res.status === 201, `status=${res.status}`);
}

async function testLearningHistory() {
  console.log('\n📚 学习历史');
  const res = await request('GET', `/learning/history/${childId}`, null, accessToken);
  assert('获取成功', res.status === 200, `status=${res.status}`);
}

async function testLearningStats() {
  console.log('\n📈 学习统计');
  const res = await request('GET', `/learning/stats/${childId}`, null, accessToken);
  assert('获取成功', res.status === 200, `status=${res.status}`);
}

async function testDeleteChild() {
  console.log('\n🗑️ 删除儿童档案');
  const res = await request('DELETE', `/children/${childId}`, null, accessToken);
  assert('删除成功', res.status === 200, `status=${res.status}`);
}

async function testUnauthorized() {
  console.log('\n🔒 未认证访问');
  const res = await request('GET', '/children', null, 'invalid_token');
  assert('返回401', res.status === 401, `status=${res.status}`);
}

async function testNotFound() {
  console.log('\n🔍 不存在的接口');
  const res = await request('GET', '/nonexistent');
  assert('返回404', res.status === 404, `status=${res.status}`);
}

// ===== 主流程 =====

async function main() {
  console.log('╔══════════════════════════════════════╗');
  console.log('║  字趣阅读 API 集成测试              ║');
  console.log(`║  BASE_URL: ${BASE_URL.padEnd(26)}║`);
  console.log('╚══════════════════════════════════════╝');

  const startTime = Date.now();

  // 按依赖顺序执行测试
  await testHealthCheck();
  await testSendSmsCode();
  await testLogin();
  await testRefreshToken();
  await testGetProfile();
  await testUpdateProfile();
  await testCreateChild();
  await testGetChildren();
  await testGetChildDetail();
  await testUpdateChild();
  await testGetBooks();
  await testGetBookDetail();
  await testRecommendedBooks();
  await testFreeBooks();
  await testBookThemes();
  await testStartAssessment();
  await testSubmitAssessment();
  await testGetAssessment();
  await testAssessmentHistory();
  await testRecordLearning();
  await testLearningHistory();
  await testLearningStats();
  await testDeleteChild();
  await testUnauthorized();
  await testNotFound();

  const duration = Date.now() - startTime;

  console.log('\n╔══════════════════════════════════════╗');
  console.log('║  测试结果                            ║');
  console.log('╠══════════════════════════════════════╣');
  console.log(`║  ✅ 通过: ${String(passed).padEnd(26)}║`);
  console.log(`║  ❌ 失败: ${String(failed).padEnd(26)}║`);
  console.log(`║  ⏱️  耗时: ${String(duration + 'ms').padEnd(26)}║`);
  console.log('╚══════════════════════════════════════╝');

  if (errors.length > 0) {
    console.log('\n❌ 失败详情:');
    errors.forEach((e, i) => console.log(`  ${i + 1}. ${e.name}: ${e.detail}`));
  }

  process.exit(failed > 0 ? 1 : 0);
}

main().catch(err => {
  console.error('测试执行出错:', err);
  process.exit(1);
});
