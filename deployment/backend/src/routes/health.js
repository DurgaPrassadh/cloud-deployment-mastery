const express = require('express');
const os = require('os');
const db = require('../db');

const router = express.Router();

// Health check endpoint
router.get('/', async (req, res) => {
  let dbHealthy = false;
  
  try {
    await db.query('SELECT 1');
    dbHealthy = true;
  } catch (error) {
    console.error('Database health check failed:', error.message);
  }

  const status = dbHealthy ? 'healthy' : 'degraded';
  
  res.json({
    success: true,
    data: {
      status,
      database: dbHealthy,
      api: true,
      timestamp: new Date().toISOString(),
    },
  });
});

// System metrics endpoint
router.get('/metrics', async (req, res) => {
  try {
    const cpus = os.cpus();
    const totalMemory = os.totalmem();
    const freeMemory = os.freemem();
    const uptime = os.uptime();

    // Calculate CPU usage (simplified)
    const cpuUsage = cpus.reduce((acc, cpu) => {
      const total = Object.values(cpu.times).reduce((a, b) => a + b, 0);
      const idle = cpu.times.idle;
      return acc + ((total - idle) / total) * 100;
    }, 0) / cpus.length;

    // Memory usage percentage
    const memoryUsage = ((totalMemory - freeMemory) / totalMemory) * 100;

    res.json({
      success: true,
      data: {
        cpu_usage: Math.round(cpuUsage * 100) / 100,
        memory_usage: Math.round(memoryUsage * 100) / 100,
        disk_usage: 0, // Would need additional library for disk usage
        network_in: 0,
        network_out: 0,
        active_connections: 0,
        uptime_seconds: Math.round(uptime),
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;