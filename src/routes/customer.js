const express = require('express');
const router = express.Router();
const customerController = require('../controllers/customerController');
const { auth } = require('../middleware/auth');
const { checkAppVersion } = require('../middleware/versionCheck');

/**
 * All customer routes require authentication + current app version
 * Mobile app must send valid JWT token and current X-App-Version-Code header
 */

// Health check for customer service
router.get('/health', auth, customerController.healthCheck);

// Get total customer count
router.get('/count', auth, checkAppVersion, customerController.getCount);

// Sync customers (paginated download for offline use)
router.get('/sync', auth, checkAppVersion, customerController.sync);

// Search customers by name, ID, or mobile
router.get('/search', auth, checkAppVersion, customerController.search);

// Get customers by zone (optional - for filtered sync)
router.get('/zone/:zoneCode', auth, checkAppVersion, customerController.getByZone);

// Get customer by OLD_CONSUMER_ID (must be last to avoid route conflicts)
router.get('/:id', auth, checkAppVersion, customerController.getById);

module.exports = router;
