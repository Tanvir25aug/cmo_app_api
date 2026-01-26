const express = require('express');
const router = express.Router();
const customerController = require('../controllers/customerController');
const { auth } = require('../middleware/auth');

/**
 * All customer routes require authentication
 * Mobile app must send valid JWT token
 */

// Health check for customer service
router.get('/health', auth, customerController.healthCheck);

// Get total customer count
router.get('/count', auth, customerController.getCount);

// Sync customers (paginated download for offline use)
router.get('/sync', auth, customerController.sync);

// Search customers by name, ID, or mobile
router.get('/search', auth, customerController.search);

// Get customers by zone (optional - for filtered sync)
router.get('/zone/:zoneCode', auth, customerController.getByZone);

// Get customer by OLD_CONSUMER_ID (must be last to avoid route conflicts)
router.get('/:id', auth, customerController.getById);

module.exports = router;
