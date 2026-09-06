const express = require('express');
const client = require('prom-client');

const app = express();
const PORT = process.env.PORT || 3000;

// --- Metricas Prometheus ---
const register = new client.Registry();
client.collectDefaultMetrics({ register });

const httpRequestCounter = new client.Counter({
  name: 'http_requests_total',
  help: 'Total de peticiones HTTP',
  labelNames: ['method', 'route', 'status'],
});
const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duracion de las peticiones HTTP en segundos',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.05, 0.1, 0.3, 0.5, 1, 2, 5],
});
register.registerMetric(httpRequestCounter);
register.registerMetric(httpRequestDuration);

// Middleware de instrumentacion
app.use((req, res, next) => {
  const end = httpRequestDuration.startTimer();
  res.on('finish', () => {
    const labels = { method: req.method, route: req.path, status: res.statusCode };
    httpRequestCounter.inc(labels);
    end(labels);
  });
  next();
});

// --- Rutas de la aplicacion ---
app.get('/', (req, res) => {
  res.json({ message: 'DevOps Demo App', version: process.env.APP_VERSION || '1.0.0' });
});

// Health check para Kubernetes (liveness/readiness)
app.get('/healthz', (req, res) => res.status(200).json({ status: 'ok' }));
app.get('/ready', (req, res) => res.status(200).json({ status: 'ready' }));

// Endpoint scrapeado por Prometheus
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// Endpoint de negocio de ejemplo
app.get('/api/users', (req, res) => {
  res.json([{ id: 1, name: 'Ada' }, { id: 2, name: 'Alan' }]);
});

// Solo levantamos el server si el archivo se ejecuta directamente
if (require.main === module) {
  app.listen(PORT, () => console.log(`App escuchando en el puerto ${PORT}`));
}

module.exports = app;
