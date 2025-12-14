const express = require('express');
const axios = require('axios');
const app = express();
const PORT = 3000;

const BACKEND_URL = process.env.BACKEND_URL || 'http://backend-service.backend-ns.svc.cluster.local:8080';
const ERROR_GENERATOR_URL = process.env.ERROR_GENERATOR_URL || 'http://error-generator-service.shared-ns.svc.cluster.local:4000';

let requestCount = 0;

app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'frontend', timestamp: new Date().toISOString() });
});

// Main endpoint that calls backend
app.get('/', async (req, res) => {
  requestCount++;
  try {
    console.log(`[${new Date().toISOString()}] Frontend request #${requestCount} - calling backend`);
    
    // Make request to backend
    const response = await axios.get(`${BACKEND_URL}/api/data`, {
      timeout: 5000,
      headers: { 'X-Request-ID': `frontend-${requestCount}` }
    });
    
    res.json({
      service: 'frontend',
      requestId: requestCount,
      backendResponse: response.data,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Frontend error:`, error.message);
    res.status(500).json({
      service: 'frontend',
      error: error.message,
      requestId: requestCount,
      timestamp: new Date().toISOString()
    });
  }
});

// Endpoint that generates errors by calling error generator
app.get('/trigger-error', async (req, res) => {
  requestCount++;
  try {
    console.log(`[${new Date().toISOString()}] Frontend triggering error #${requestCount}`);
    
    const response = await axios.get(`${ERROR_GENERATOR_URL}/generate-error`, {
      timeout: 5000
    });
    
    res.json({
      service: 'frontend',
      message: 'Error triggered',
      errorGeneratorResponse: response.data,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Frontend error trigger failed:`, error.message);
    res.status(500).json({
      service: 'frontend',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Endpoint that makes multiple concurrent requests
app.get('/stress-test', async (req, res) => {
  const count = parseInt(req.query.count) || 10;
  const promises = [];
  
  for (let i = 0; i < count; i++) {
    promises.push(
      axios.get(`${BACKEND_URL}/api/data`, { timeout: 3000 })
        .catch(err => ({ error: err.message }))
    );
  }
  
  const results = await Promise.all(promises);
  const success = results.filter(r => !r.error).length;
  const failures = results.filter(r => r.error).length;
  
  res.json({
    service: 'frontend',
    totalRequests: count,
    successful: success,
    failed: failures,
    timestamp: new Date().toISOString()
  });
});

// Metrics endpoint
app.get('/metrics', (req, res) => {
  res.json({
    service: 'frontend',
    totalRequests: requestCount,
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Frontend service listening on port ${PORT}`);
  console.log(`Backend URL: ${BACKEND_URL}`);
  console.log(`Error Generator URL: ${ERROR_GENERATOR_URL}`);
});

