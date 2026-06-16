# HTTPS 部署 Runbook

> 状态：技术 100% 就绪 | 触发条件：域名 + 服务器到位 | 预计耗时：30 分钟

---

## 一、前置条件（非技术阻塞）

| # | 条件 | 状态 | 负责人 | 预计耗时 |
|---|------|:---:|--------|---------|
| 1 | 域名购买（推荐 `ziqu.com`） | 🔴 待执行 | 运营/Team Lead | 1天 |
| 2 | 云服务器采购（推荐 2C4G，CentOS/Ubuntu） | 🔴 待执行 | 运营/Team Lead | 1天 |
| 3 | ICP 备案（大陆服务器必须，需营业执照） | 🔴 待启动 | 运营 | ~20工作日 |
| 4 | 公司注册（备案前提） | 🔴 待启动 | 运营/法务 | 2-4周 |

---

## 二、服务器到位后 — 30 分钟部署清单

### Step 1: 环境初始化（5 分钟）

```bash
# 安装 Node.js 20 LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# 安装 MongoDB 8.0
# Ubuntu: https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-ubuntu/
# 或使用 Docker: docker run -d --name mongo -p 27017:27017 mongo:8

# 安装 Redis
sudo apt-get install -y redis-server

# 安装 Nginx
sudo apt-get install -y nginx

# 安装 PM2 + certbot
sudo npm install -g pm2
sudo apt-get install -y certbot python3-certbot-nginx
```

### Step 2: 部署应用（5 分钟）

```bash
# 创建目录
sudo mkdir -p /opt/qudu-api/uploads/audio/books
sudo chown -R $USER:$USER /opt/qudu-api

# 上传代码（通过 git clone 或 rsync）
cd /opt/qudu-api
# git clone <repo-url> .  或  rsync -avz ./ user@server:/opt/qudu-api/

# 安装依赖
npm ci --production

# 配置环境变量
cp .env.example .env
# 编辑 .env: 修改 JWT_SECRET（强随机32位+）、MONGODB_URI、REDIS_URL
nano .env
```

### Step 3: 导入数据（2 分钟）

```bash
cd /opt/qudu-api
node scripts/seed.js
node scripts/seed_L2_books.js
node scripts/seed_L345_characters.js
```

### Step 4: 启动 PM2（1 分钟）

```bash
pm2 start ecosystem.config.js
pm2 save
pm2 startup  # 开机自启
```

验证：`curl http://localhost:3001/api/v1/characters?level=1&pageSize=1`

### Step 5: DNS 解析（2 分钟）

在域名 DNS 管理后台添加 A 记录：
```
api.ziqu.com  →  <服务器公网IP>
```

验证：`dig api.ziqu.com`（等 DNS 生效，通常 1-5 分钟）

### Step 6: SSL 证书（3 分钟）

```bash
# Let's Encrypt 自动获取
sudo certbot certonly --webroot -w /var/www/certbot \
  -d api.ziqu.com

# 证书路径（自动生成）
# /etc/letsencrypt/live/api.ziqu.com/fullchain.pem
# /etc/letsencrypt/live/api.ziqu.com/privkey.pem

# 测试自动续期
sudo certbot renew --dry-run
```

### Step 7: 部署 Nginx（3 分钟）

```bash
# 复制配置文件
sudo cp nginx/production.conf /etc/nginx/sites-available/qudu-api
sudo ln -s /etc/nginx/sites-available/qudu-api /etc/nginx/sites-enabled/

# 创建 certbot webroot 目录
sudo mkdir -p /var/www/certbot

# 测试配置
sudo nginx -t

# 重启 Nginx
sudo systemctl reload nginx
```

### Step 8: 验证 HTTPS（2 分钟）

```bash
# 健康检查
curl https://api.ziqu.com/api/v1/ping

# 字库 API
curl https://api.ziqu.com/api/v1/characters?level=1

# SSL 评级检查
# 浏览器打开: https://www.ssllabs.com/ssltest/analyze.html?d=api.ziqu.com
```

---

## 三、配置文件就绪清单

| 文件 | 路径 | 状态 |
|------|------|:---:|
| Nginx 生产配置 | `nginx/production.conf` (177行) | ✅ |
| PM2 生态系统配置 | `ecosystem.config.js` | ✅ |
| SSL 方案文档 | `DEPLOYMENT.md` §5.5 | ✅ |
| 环境变量模板 | `.env.example` | ✅ |
| 数据种子脚本 | `scripts/seed.js` + `seed_L2_books.js` + `seed_L345_characters.js` | ✅ |

---

## 四、Nginx 配置要点

`nginx/production.conf` 已包含：

| 功能 | 配置 |
|------|------|
| HTTP→HTTPS 强制跳转 | `return 301 https://$host$request_uri` |
| SSL 协议 | TLSv1.2 + TLSv1.3（Mozilla Intermediate） |
| HSTS | 注释状态，确认正常后开启 |
| API 反代 | `proxy_pass http://qudu_api`（upstream→127.0.0.1:3001） |
| 静态资源缓存 | `/uploads/` 7天 + Cache-Control immutable |
| 音频断点续传 | `/audio/` Accept-Ranges bytes |
| Swagger 内网限制 | 仅 127.0.0.1 + 私有IP段可访问 |
| 健康检查 | `/api/v1/ping` 不记日志无缓冲 |
| Gzip 压缩 | text/css/js/json/svg+xml |
| 安全头 | X-Frame-Options/X-Content-Type/X-XSS/Referrer-Policy |

---

## 五、回滚方案

如遇问题：
```bash
# 切回 HTTP 模式
sudo cp nginx/production.conf /etc/nginx/sites-available/qudu-api
# 注释掉 443 server block，启用 80 server block
sudo nginx -t && sudo systemctl reload nginx
```

---

*文档版本：v1.0 | 创建日期：2026-06-14 | 维护：后端负责人*
