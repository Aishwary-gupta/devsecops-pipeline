const request = require('supertest');
const app = require('../src/app');

describe('DevSecOps Service Unit & Integration Tests', () => {

  describe('GET /health', () => {
    it('should return 200 OK with healthy status and uptime', async () => {
      const res = await request(app).get('/health');
      expect(res.statusCode).toEqual(200);
      expect(res.body.status).toEqual('healthy');
      expect(res.body).toHaveProperty('timestamp');
      expect(res.body).toHaveProperty('uptime');
    });
  });

  describe('GET /ready', () => {
    it('should return 200 OK with readiness state', async () => {
      const res = await request(app).get('/ready');
      expect(res.statusCode).toEqual(200);
      expect(res.body.status).toEqual('ready');
      expect(res.body.version).toEqual('1.0.0');
    });
  });

  describe('GET /api/info', () => {
    it('should return service metadata and active security checks', async () => {
      const res = await request(app).get('/api/info');
      expect(res.statusCode).toEqual(200);
      expect(res.body.service).toEqual('secure-devsecops-service');
      expect(Array.isArray(res.body.securityChecks)).toBe(true);
      expect(res.body.securityChecks).toContain('SonarQube SAST');
      expect(res.body.securityChecks).toContain('Trivy Container & Secret Scan');
    });
  });

  describe('POST /api/data', () => {
    it('should successfully accept valid payload string', async () => {
      const res = await request(app)
        .post('/api/data')
        .send({ payload: 'DevSecOps automated test verification' });
      expect(res.statusCode).toEqual(201);
      expect(res.body.message).toEqual('Data processed securely');
      expect(res.body.data).toEqual('DevSecOps automated test verification');
    });

    it('should reject request when payload is missing or empty', async () => {
      const res = await request(app)
        .post('/api/data')
        .send({});
      expect(res.statusCode).toEqual(400);
      expect(res.body).toHaveProperty('error');
    });

    it('should reject request when payload is non-string', async () => {
      const res = await request(app)
        .post('/api/data')
        .send({ payload: 12345 });
      expect(res.statusCode).toEqual(400);
      expect(res.body.error).toEqual('Valid payload string is required');
    });
  });

  describe('404 Route Handling', () => {
    it('should return 404 for unknown endpoints', async () => {
      const res = await request(app).get('/non-existent-endpoint');
      expect(res.statusCode).toEqual(404);
      expect(res.body.error).toEqual('Endpoint not found');
    });
  });

  describe('Security Headers (Helmet)', () => {
    it('should set secure HTTP response headers', async () => {
      const res = await request(app).get('/health');
      expect(res.headers).toHaveProperty('x-dns-prefetch-control');
      expect(res.headers).toHaveProperty('x-content-type-options', 'nosniff');
    });
  });

  describe('Error Handling Middleware', () => {
    let consoleSpy;

    beforeEach(() => {
      consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    });

    afterEach(() => {
      consoleSpy.mockRestore();
    });

    it('should catch unhandled errors and return 500 without leaking stack traces', async () => {
      const res = await request(app).get('/api/test-error');
      expect(res.statusCode).toEqual(500);
      expect(res.body.error).toEqual('Internal Server Error');
      expect(res.body.code).toEqual('ERR_INTERNAL');
      expect(consoleSpy).toHaveBeenCalledWith(
        'Handled application error:',
        'Simulated internal error for coverage'
      );
    });
  });

});
