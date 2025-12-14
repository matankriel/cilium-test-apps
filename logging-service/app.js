const express = require('express');
const fs = require('fs');
const app = express();
const PORT = 5000;

let logCount = 0;
let errorLogCount = 0;

app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    service: 'logging-service',
    timestamp: new Date().toISOString() 
  });
});

// Log endpoint - sometimes fails to test error visibility
app.post('/log', (req, res) => {
  logCount++;
  
  // 5% chance of failing
  if (Math.random() < 0.05) {
    errorLogCount++;
    console.error(`[${new Date().toISOString()}] Logging service error - failed to process log`);
    return res.status(500).json({
      error: 'Logging service error',
      service: 'logging-service',
      timestamp: new Date().toISOString()
    });
  }
  
  const logEntry = {
    ...req.body,
    receivedAt: new Date().toISOString(),
    logId: logCount
  };
  
  console.log(`[${new Date().toISOString()}] Log received:`, JSON.stringify(logEntry));
  
  // In a real scenario, you'd write to a database or log aggregation service
  // For testing, we just log to console and return success
  
  res.json({
    status: 'logged',
    service: 'logging-service',
    logId: logCount,
    timestamp: new Date().toISOString()
  });
});

// Get all logs (in-memory for testing)
app.get('/logs', (req, res) => {
  res.json({
    service: 'logging-service',
    totalLogs: logCount,
    errorLogs: errorLogCount,
    timestamp: new Date().toISOString()
  });
});

// Metrics endpoint
app.get('/metrics', (req, res) => {
  res.json({
    service: 'logging-service',
    totalLogs: logCount,
    errorLogs: errorLogCount,
    successRate: ((logCount - errorLogCount) / logCount * 100) || 0,
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Logging service listening on port ${PORT}`);
});

