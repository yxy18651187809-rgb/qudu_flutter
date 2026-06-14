# 字趣阅读 - 后端部署文档

## 一、环境要求

| 依赖 | 最低版本 | 推荐版本 | 说明 |
|------|---------|---------|------|
| Node.js | 18.0+ | 20.x LTS | 使用ES2022特性 |
| MongoDB | 6.0+ | 7.0 | 主数据库 |
| Redis | 6.0+ | 7.0 | 验证码缓存、Session存储 |
| npm | 9.0+ | 10.x | 包管理 |

## 二、本地开发环境搭建

### 2.1 快速启动（Docker Compose）

```bash
# 1. 进入项目目录
cd 03-后端/qudu-api

# 2. 复制环境配置
cp .env.example .env

# 3. 启动 MongoDB + Redis
docker-compose up -d

# 4. 安装依赖
npm install

# 5. 导入种子数据
npm run seed

# 6. 启动开发服务器
npm run dev
```

启动成功后：
- API服务：http://localhost:3001
- 健康检查：http://localhost:3001/api/v1/ping
- Swagger文档：http://localhost:3001/api-docs
- Swagger JSON：http://localhost:3001/api-docs.json

### 2.2 手动安装（无Docker）

#### MongoDB

```bash
# macOS
brew tap mongodb/brew
brew install mongodb-community
brew services start mongodb-community

# 验证
mongosh --eval "db.version()"
```

#### Redis

```bash
# macOS
brew install redis
brew services start redis

# 验证
redis-cli ping  # 应返回 PONG
```

#### Node.js

```bash
# 推荐使用 nvm 管理版本
nvm install 20
nvm use 20
node --version  # v20.x.x
```

## 三、Docker Compose 配置

项目根目录 `docker-compose.yml`：

```yaml
version: '3.8'

services:
  mongodb:
    image: mongo:7.0
    container_name: qudu-mongodb
    restart: unless-stopped
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: qudu
      MONGO_INITDB_ROOT_PASSWORD: qudu_dev_2026
    volumes:
      - mongodb_data:/data/db
    command: mongod --auth

  redis:
    image: redis:7.0-alpine
    container_name: qudu-redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes

volumes:
  mongodb_data:
  redis_data:
```

对应的 `.env` 配置：

```env
MONGODB_URI=mongodb://qudu:qudu_dev_2026@localhost:27017/qudu?authSource=admin
REDIS_URL=redis://localhost:6379
```

## 四、环境变量说明

| 变量 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| PORT | 否 | 3001 | 服务端口 |
| MONGODB_URI | 是 | mongodb://localhost:27017/qudu | MongoDB连接串 |
| REDIS_URL | 是 | redis://localhost:6379 | Redis连接URL |
| JWT_SECRET | 是 | dev-secret-change-in-production | JWT签名密钥，生产环境必须修改 |
| JWT_ACCESS_EXPIRES_IN | 否 | 2h | accessToken有效期 |
| JWT_REFRESH_EXPIRES_IN | 否 | 7d | refreshToken有效期 |
| SMS_PROVIDER | 否 | mock | 短信服务商（mock/tencent/alibaba） |
| SMS_MOCK_CODE | 否 | 123456 | 开发环境固定验证码 |
| OSS_REGION | 否 | cn-hangzhou | 阿里云OSS区域 |
| OSS_BUCKET | 否 | qudu-assets | OSS Bucket名 |
| OSS_ACCESS_KEY_ID | 否 | - | OSS AccessKey |
| OSS_ACCESS_KEY_SECRET | 否 | - | OSS SecretKey |
| WECHAT_APP_ID | 否 | - | 微信小程序AppID |
| WECHAT_APP_SECRET | 否 | - | 微信小程序Secret |

## 五、生产环境部署

### 5.1 推荐架构

```
[Nginx] → [Node.js ×2] → [MongoDB 副本集]
                  ↓
              [Redis Sentinel]
```

### 5.2 PM2 进程管理

```bash
# 安装 PM2
npm install -g pm2

# 启动（集群模式，2个进程）
pm2 start src/app.js -i 2 --name qudu-api

# 常用命令
pm2 status          # 查看状态
pm2 logs qudu-api   # 查看日志
pm2 restart qudu-api  # 重启
pm2 stop qudu-api   # 停止
```

### 5.3 生产环境检查清单

- [ ] `JWT_SECRET` 已替换为强随机密钥（≥32位）
- [ ] `SMS_PROVIDER` 已切换为正式服务商
- [ ] MongoDB 已启用认证
- [ ] Redis 已设置密码
- [ ] Nginx 已配置 HTTPS + 反向代理
- [ ] CORS 已限制为前端域名
- [ ] 日志已接入收集系统
- [ ] 健康检查已配置监控告警

### 5.4 Nginx 配置

完整生产配置见：`nginx/production.conf`

关键配置说明：
- API 反向代理至 `127.0.0.1:3001`（upstream qudu_api）
- 静态资源 `/uploads/` → `/opt/qudu-api/uploads/`（7天缓存）
- 音频资源 `/audio/` → `/opt/qudu-api/uploads/audio/`（7天缓存 + 断点续传）
- Swagger `/api-docs` 仅内网访问
- 健康检查 `/api/v1/ping` 不记日志
- Gzip 压缩已启用

### 5.5 SSL 证书方案

| 方案 | 费用 | 有效期 | 自动续期 | 适用 |
|------|------|--------|----------|------|
| **Let's Encrypt** | 免费 | 90天 | ✅ certbot | 推荐首选 |
| **阿里云免费SSL** | 免费 | 1年 | ❌ 手动 | 自有域名在阿里云 |
| **腾讯云免费SSL** | 免费 | 1年 | ❌ 手动 | 自有域名在腾讯云 |
| **TrustAsia/其他** | ¥500-5000/年 | 1年 | ❌ | 需要OV/EV证书时 |

**推荐方案：Let's Encrypt + certbot 自动续期**

```bash
# 安装 certbot（macOS）
brew install certbot

# 获取证书（HTTP验证方式，需域名已解析到服务器）
sudo certbot certonly --webroot -w /var/www/certbot \
  -d api.ziqu.com -d ziqu.com

# 证书路径（自动生成）
# 证书: /etc/letsencrypt/live/api.ziqu.com/fullchain.pem
# 私钥: /etc/letsencrypt/live/api.ziqu.com/privkey.pem

# 测试自动续期（每90天自动检查）
sudo certbot renew --dry-run
```

**部署步骤：**
1. 购买域名（如 ziqu.com）并完成ICP备案（中国大陆服务器必须）
2. 域名 DNS 解析到服务器IP
3. 安装 Let's Encrypt 证书
4. 部署 `nginx/production.conf` 到 `/opt/homebrew/etc/nginx/servers/`
5. `nginx -t && brew services restart nginx`

**⚠️ 中国大陆特殊要求：**
- 服务器需完成ICP备案（约20个工作日）
- 小程序 API 域名需在微信后台配置白名单
- 建议使用 CDN（阿里云CDN/腾讯云CDN）加速静态资源

## 六、数据库管理

### 6.1 索引策略

生产环境需确保以下索引已创建：

```javascript
// users
db.users.createIndex({ phone: 1 }, { unique: true });

// children
db.children.createIndex({ parentId: 1, isDeleted: 1 });

// characters
db.characters.createIndex({ level: 1, sortOrder: 1 });
db.characters.createIndex({ character: 1 }, { unique: true });

// books
db.books.createIndex({ level: 1, status: 1, sortOrder: 1 });
db.books.createIndex({ isFree: 1, status: 1 });
db.books.createIndex({ theme: 1 });

// book_pages
db.bookpages.createIndex({ bookId: 1, pageNumber: 1 });

// assessments
db.assessments.createIndex({ childId: 1, status: 1 });
db.assessments.createIndex({ childId: 1, createdAt: -1 });

// word_masteries
db.wordmasteries.createIndex({ childId: 1, characterId: 1 }, { unique: true });
db.wordmasteries.createIndex({ childId: 1, nextReviewAt: 1 });

// learning_records
db.learningrecords.createIndex({ childId: 1, type: 1, createdAt: -1 });
db.learningrecords.createIndex({ childId: 1, createdAt: -1 });
```

### 6.2 种子数据

```bash
# 导入52字+2本绘本
npm run seed

# 清空重建
node scripts/seed.js --reset
```

### 6.3 数据备份

```bash
# 手动备份
mongodump --uri="mongodb://qudu:password@localhost:27017/qudu" --out=./backup/$(date +%Y%m%d)

# 恢复
mongorestore --uri="mongodb://qudu:password@localhost:27017/qudu" ./backup/20260421
```

## 七、常见问题

### Q: npm install 报错？
```bash
# 清除缓存重试
rm -rf node_modules package-lock.json
npm cache clean --force
npm install
```

### Q: MongoDB连接失败？
```bash
# 检查MongoDB是否运行
docker ps | grep mongo
# 或
brew services list | grep mongo

# 检查连接串是否正确
mongosh "mongodb://qudu:qudu_dev_2026@localhost:27017/qudu?authSource=admin"
```

### Q: 开发环境验证码是什么？
固定为 `123456`，配置项 `SMS_PROVIDER=mock` 时生效。

### Q: 如何验证API是否正常？
```bash
# 健康检查
curl http://localhost:3001/health

# 发送验证码
curl -X POST http://localhost:3001/api/v1/auth/sms/send \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000"}'

# 登录
curl -X POST http://localhost:3001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","code":"123456"}'
```

---

*文档版本：v1.1*  
*创建日期：2026-04-21*  
*最后更新：2026-06-13（端口3000→3001，新增SSL证书方案+Nginx生产配置）*  
*维护者：后端负责人*
