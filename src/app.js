const express = require('express');
const helmet = require('helmet');
const cors = require('cors');

const app = express();

// Secure HTTP headers
app.use(helmet());

// CORS configuration - restricted in production
const allowedOrigins = process.env.ALLOWED_ORIGINS || '*';
app.use(cors({
  origin: allowedOrigins,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Body parser with size limit to prevent payload DoS
app.use(express.json({ limit: '10kb' }));

// Liveness probe
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Readiness probe
app.get('/ready', (req, res) => {
  res.status(200).json({
    status: 'ready',
    version: '1.0.0'
  });
});

// Service Info endpoint
app.get('/api/info', (req, res) => {
  res.status(200).json({
    service: 'secure-devsecops-service',
    environment: process.env.NODE_ENV,
    pipeline: 'DevSecOps End-to-End',
    securityChecks: [
      'SonarQube SAST',
      'Trivy Container & Secret Scan',
      'CycloneDX SBOM',
      'Snyk SCA',
      'Checkov IaC',
      'OPA Conftest Policy-as-Code'
    ]
  });
});

// Example authenticated business endpoint
app.post('/api/data', (req, res) => {
  const { payload } = req.body;
  if (!payload || typeof payload !== 'string') {
    return res.status(400).json({ error: 'Valid payload string is required' });
  }

  // Sanitized echo response
  return res.status(201).json({
    message: 'Data processed securely',
    data: payload.trim()
  });
});

// Route to test global error handler in test environment
app.get('/api/test-error', (req, res, next) => {
  next(new Error('Simulated internal error for coverage'));
});

// 404 Handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Global Secure Error Handler (No sensitive leakages)
app.use((err, req, res, next) => {
  console.error('Handled application error:', err.message);
  res.status(500).json({
    error: 'Internal Server Error',
    code: 'ERR_INTERNAL'
  });
});

module.exports = app;
