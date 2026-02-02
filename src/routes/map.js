const express = require('express');
const router = express.Router();
const mapController = require('../controllers/mapController');
const { auth } = require('../middleware/auth');

// All routes are protected
router.use(auth);

// Get all map data (NOCS + DCUs)
router.get('/', mapController.getAllMapData);

// NOCS routes
router.get('/nocs', mapController.getAllNOCS);
router.get('/nocs/:id', mapController.getNOCSById);

// DCU routes
router.get('/dcus', mapController.getAllDCUs);
router.get('/dcus/:id', mapController.getDCUById);

// CMO routes (from MeterInfo table)
router.get('/cmos', mapController.getCMOsWithCoordinates);
router.get('/cmos/:id', mapController.getCMOById);

module.exports = router;
