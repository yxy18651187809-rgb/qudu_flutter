module.exports = {
  apps: [{
    name: 'qudu-api',
    script: 'src/app.js',
    cwd: '/Users/yangxiaoyan/WorkBuddy/20260420213331/03-后端/qudu-api',
    instances: 1,
    exec_mode: 'fork',
    watch: false,
    max_memory_restart: '300M',
    env: {
      NODE_ENV: 'development',
      PORT: 3001
    },
    log_date_format: 'YYYY-MM-DD HH:mm:ss',
    error_file: './logs/pm2-error.log',
    out_file: './logs/pm2-out.log',
    merge_logs: true,
    autorestart: true,
    max_restarts: 10,
    restart_delay: 3000,
    // 优雅关闭
    kill_timeout: 5000,
    listen_timeout: 10000,
    shutdown_with_message: true
  }]
};
