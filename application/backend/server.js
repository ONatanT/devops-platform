const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

// Health check endpoint (critical for ECS)
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    environment: process.env.ENVIRONMENT || 'unknown',
    version: '1.0.0'
  });
});

// Main API endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'DevOps Platform API',
    environment: process.env.ENVIRONMENT || 'unknown',
    timestamp: new Date().toISOString()
  });
});

// API info endpoint
app.get('/api/info', (req, res) => {
  res.json({
    service: 'backend-api',
    version: '1.0.0',
    environment: process.env.ENVIRONMENT || 'unknown',
    uptime: process.uptime(),
    memory: process.memoryUsage()
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.ENVIRONMENT || 'unknown'}`);
});
