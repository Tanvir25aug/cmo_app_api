const express = require('express');
const router = express.Router();
const customerController = require('../controllers/customerController');
const { auth } = require('../middleware/auth');
/**
 * Customer routes require authentication only — no version check.
 * These routes must remain accessible to all app versions so that
 * customer search and offline sync are never blocked by a version gate.
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
