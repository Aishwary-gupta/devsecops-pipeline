require('dotenv').config();
const app = require('./app');

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, () => {
  console.log(`[SECURE-SERVER] Running on port ${PORT} in ${process.env.NODE_ENV || 'development'} mode`);
});

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`[SECURE-SERVER] Error: Port ${PORT} is already in use.`);
    console.error(`[SECURE-SERVER] To fix: Stop the existing process using port ${PORT} or run with a different port (e.g. $env:PORT=3001; npm start).`);
  } else {
    console.error('[SECURE-SERVER] Server error:', err);
  }
  process.exit(1);
});

// Graceful shutdown handling for container runtimes (Kubernetes / Docker)
const shutdown = (signal) => {
  console.log(`[SECURE-SERVER] Received ${signal}. Shutting down gracefully...`);
  server.close(() => {
    console.log('[SECURE-SERVER] HTTP server closed. Process terminating.');
    process.exit(0);
  });

  // Force shutdown if connections do not close in 10s
  setTimeout(() => {
    console.error('[SECURE-SERVER] Forcefully terminating after timeout');
    process.exit(1);
  }, 10000);
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
