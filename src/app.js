const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const path = require('path');
require('dotenv').config();

const routes = require('./routes');
const { errorHandler, notFound } = require('./middleware/errorHandler');
const logger = require('./utils/logger');
const { apiLimiter } = require('./middleware/rateLimiter');

// Create Express app
const app = express();

// Security middleware with custom CSP for static pages
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      scriptSrcAttr: ["'unsafe-inline'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com", "https://cdnjs.cloudflare.com"],
      fontSrc: ["'self'", "https://fonts.gstatic.com", "https://cdnjs.cloudflare.com"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'"],
      formAction: ["'self'"],
      frameAncestors: ["'self'"]
    }
  },
  crossOriginOpenerPolicy: false,
  originAgentCluster: false
}));

// CORS configuration
const corsOptions = {
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true,
  optionsSuccessStatus: 200
};
app.use(cors(corsOptions));

// Compression middleware
app.use(compression());

// Body parser middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined', {
    stream: {
      write: (message) => logger.info(message.trim())
    }
  }));
}

// Global rate limiter
app.use(apiLimiter);

// Static files (uploaded images)
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Public static files (download page, etc.)
app.use(express.static(path.join(__dirname, '../public')));

// Download page route
app.get('/download', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/download.html'));
});

// API routes
const apiPrefix = process.env.API_PREFIX || '/api';
app.use(apiPrefix, routes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Welcome to CMO API',
    version: '1.0.0',
    endpoints: {
      health: `${apiPrefix}/health`,
      auth: `${apiPrefix}/auth`,
      cmo: `${apiPrefix}/cmo`,
      customer: `${apiPrefix}/customer`,
      customers: `${apiPrefix}/customers`,
      app: `${apiPrefix}/app`,
      downloadPage: '/download',
      documentation: '/api-docs'
    }
  });
});

// Swagger documentation (will be added later)
// app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

// 404 handler
app.use(notFound);

// Error handler (must be last)
app.use(errorHandler);

module.exports = app;
