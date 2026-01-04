const express = require('express');
const { initializeDatabase, getPool, closeDatabase } = require('./db/connection');
const { initializeSchema } = require('./db/schema');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Database configuration from environment variables
const dbConfig = {
  host: process.env.DB_HOST,
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'appdb',
  user: process.env.DB_USER || 'dbadmin',
  password: process.env.DB_PASSWORD
};

// Initialize database on startup
let dbInitialized = false;

async function setupDatabase() {
  try {
    if (dbConfig.host && dbConfig.password) {
      console.log('Initializing database connection...');
      initializeDatabase(dbConfig);
      await initializeSchema();
      dbInitialized = true;
      console.log('Database ready');
    } else {
      console.warn('Database credentials not provided - running without database');
    }
  } catch (error) {
    console.error('Failed to initialize database:', error.message);
    // Don't crash - allow app to run without database for testing
  }
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    environment: process.env.ENVIRONMENT || 'unknown',
    version: '1.0.0',
    database: dbInitialized ? 'connected' : 'not connected'
  });
});

// Main endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'DevOps Platform API',
    environment: process.env.ENVIRONMENT || 'unknown',
    timestamp: new Date().toISOString(),
    database: dbInitialized ? 'connected' : 'not connected'
  });
});

// API info endpoint
app.get('/api/info', (req, res) => {
  res.json({
    service: 'backend-api',
    version: '1.0.0',
    environment: process.env.ENVIRONMENT || 'unknown',
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    database: dbInitialized ? 'connected' : 'not connected'
  });
});

// CRUD Endpoints for Users

// Create user
app.post('/api/users', async (req, res) => {
  if (!dbInitialized) {
    return res.status(503).json({ error: 'Database not available' });
  }

  const { name, email } = req.body;

  if (!name || !email) {
    return res.status(400).json({ error: 'Name and email are required' });
  }

  try {
    const pool = getPool();
    const result = await pool.query(
      'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING *',
      [name, email]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating user:', error);
    if (error.code === '23505') { // Unique violation
      res.status(409).json({ error: 'Email already exists' });
    } else {
      res.status(500).json({ error: 'Internal server error' });
    }
  }
});

// Get all users
app.get('/api/users', async (req, res) => {
  if (!dbInitialized) {
    return res.status(503).json({ error: 'Database not available' });
  }

  try {
    const pool = getPool();
    const result = await pool.query('SELECT * FROM users ORDER BY created_at DESC');
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get user by ID
app.get('/api/users/:id', async (req, res) => {
  if (!dbInitialized) {
    return res.status(503).json({ error: 'Database not available' });
  }

  const { id } = req.params;

  try {
    const pool = getPool();
    const result = await pool.query('SELECT * FROM users WHERE id = $1', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching user:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update user
app.put('/api/users/:id', async (req, res) => {
  if (!dbInitialized) {
    return res.status(503).json({ error: 'Database not available' });
  }

  const { id } = req.params;
  const { name, email } = req.body;

  if (!name && !email) {
    return res.status(400).json({ error: 'At least one field (name or email) is required' });
  }

  try {
    const pool = getPool();
    const updates = [];
    const values = [];
    let paramCount = 1;

    if (name) {
      updates.push(`name = $${paramCount++}`);
      values.push(name);
    }
    if (email) {
      updates.push(`email = $${paramCount++}`);
      values.push(email);
    }
    updates.push(`updated_at = CURRENT_TIMESTAMP`);
    values.push(id);

    const result = await pool.query(
      `UPDATE users SET ${updates.join(', ')} WHERE id = $${paramCount} RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating user:', error);
    if (error.code === '23505') {
      res.status(409).json({ error: 'Email already exists' });
    } else {
      res.status(500).json({ error: 'Internal server error' });
    }
  }
});

// Delete user
app.delete('/api/users/:id', async (req, res) => {
  if (!dbInitialized) {
    return res.status(503).json({ error: 'Database not available' });
  }

  const { id } = req.params;

  try {
    const pool = getPool();
    const result = await pool.query('DELETE FROM users WHERE id = $1 RETURNING *', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ message: 'User deleted successfully', user: result.rows[0] });
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Start server
setupDatabase().then(() => {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`Environment: ${process.env.ENVIRONMENT || 'unknown'}`);
    console.log(`Database: ${dbInitialized ? 'Connected' : 'Not connected'}`);
  });
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, closing connections...');
  await closeDatabase();
  process.exit(0);
});