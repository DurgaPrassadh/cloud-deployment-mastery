// PM2 Ecosystem Configuration
// Run: pm2 start ecosystem.config.js

module.exports = {
  apps: [
    {
      name: 'devops-api',
      script: './src/index.js',
      instances: 'max', // Use all available CPU cores
      exec_mode: 'cluster',
      watch: false,
      max_memory_restart: '500M',
      
      // Environment variables
      env: {
        NODE_ENV: 'development',
        PORT: 3000,
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3000,
      },
      
      // Logging
      log_file: '/var/log/pm2/devops-api.log',
      out_file: '/var/log/pm2/devops-api-out.log',
      error_file: '/var/log/pm2/devops-api-error.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      
      // Auto-restart configuration
      autorestart: true,
      restart_delay: 4000,
      max_restarts: 10,
      min_uptime: '10s',
      
      // Graceful shutdown
      kill_timeout: 5000,
      listen_timeout: 10000,
      
      // Health monitoring
      exp_backoff_restart_delay: 100,
    },
  ],
};