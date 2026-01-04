const { Pool } = require('pg');

let pool = null;

// Initialize database connection pool
function initializeDatabase(config) {
  if (pool) {
    return pool;
  }

  pool = new Pool({
    host: config.host,
    port: config.port || 5432,
    database: config.database,
    user: config.user,
    password: config.password,
    max: 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
    // SSL configuration for RDS
    ssl: {
      rejectUnauthorized: false  // RDS uses self-signed certificates
    }
  });

  // Handle pool errors
  pool.on('error', (err) => {
    console.error('Unexpected database pool error:', err);
  });

  console.log('Database pool initialized with SSL');
  return pool;
}

// Get database pool
function getPool() {
  if (!pool) {
    throw new Error('Database not initialized. Call initializeDatabase() first.');
  }
  return pool;
}

// Close database connections
async function closeDatabase() {
  if (pool) {
    await pool.end();
    pool = null;
    console.log('Database pool closed');
  }
}

module.exports = {
  initializeDatabase,
  getPool,
  closeDatabase
};