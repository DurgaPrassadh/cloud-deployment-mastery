const { Pool } = require('pg');

// PostgreSQL connection pool
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT) || 5432,
  database: process.env.DB_NAME || 'devops_dashboard',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  
  // Pool configuration
  max: 20,                    // Maximum connections in pool
  idleTimeoutMillis: 30000,   // Close idle connections after 30s
  connectionTimeoutMillis: 2000, // Return error after 2s if no connection available
});

// Test connection on startup
pool.on('connect', () => {
  console.log('✅ Connected to PostgreSQL database');
});

pool.on('error', (err) => {
  console.error('❌ PostgreSQL connection error:', err.message);
});

// Query helper with error handling
const query = async (text, params) => {
  const start = Date.now();
  try {
    const result = await pool.query(text, params);
    const duration = Date.now() - start;
    console.log(`Query executed in ${duration}ms`);
    return result;
  } catch (error) {
    console.error('Database query error:', error.message);
    throw error;
  }
};

// Get single row
const getOne = async (text, params) => {
  const result = await query(text, params);
  return result.rows[0];
};

// Get all rows
const getAll = async (text, params) => {
  const result = await query(text, params);
  return result.rows;
};

module.exports = {
  pool,
  query,
  getOne,
  getAll,
};