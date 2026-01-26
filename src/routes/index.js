const express = require('express');
const router = express.Router();

// Import route modules
const authRoutes = require('./auth');
const cmoRoutes = require('./cmo');
const customerRoutes = require('./customer');

// Health check endpoint
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'CMO API is running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV
  });
});

// API routes
router.use('/auth', authRoutes);
router.use('/cmo', cmoRoutes);
router.use('/customer', customerRoutes);
router.use('/customers', customerRoutes);

module.exports = router;
