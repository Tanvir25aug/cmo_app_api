const express = require('express');
const router = express.Router();
const cmoController = require('../controllers/cmoController');
const bulkCmoController = require('../controllers/bulkCmoController');
const cmsDashboardController = require('../controllers/cmsDashboardController');
const { auth } = require('../middleware/auth');
const { upload } = require('../config/multer');
const { validateCMO } = require('../utils/validators');

// All routes require authentication
router.use(auth);

// CMS Dashboard routes (must be before /:id)
router.get('/cms-list', cmsDashboardController.getAll);
router.get('/cms-export', cmsDashboardController.getExportData);
router.get('/cms-statistics', cmsDashboardController.getStatistics);
router.post('/check-mdm-entry', cmsDashboardController.checkMDMEntry);
router.get('/unchecked-mdm', cmsDashboardController.getUncheckedMDM);
router.post('/bulk-update-mdm', cmsDashboardController.bulkUpdateMDM);

// Get routes
router.get('/', cmoController.getAll);
router.get('/statistics', cmoController.getStatistics);
router.get('/unsynced', cmoController.getUnsynced);
router.get('/bulk-stats', bulkCmoController.getBulkStats);
router.get('/:id', cmoController.getById);

// Post routes
router.post('/', validateCMO, cmoController.create);
router.post('/sync', cmoController.sync);
router.post('/bulk-sync', bulkCmoController.bulkSync);

// Put/Delete routes
router.put('/:id', validateCMO, cmoController.update);
router.delete('/:id', cmoController.delete);

// Upload routes (with file handling)
router.post(
  '/:id/upload-meter-image',
  upload.single('meterImage'),
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({ success: false, message: 'No file uploaded' });
      }

      const filePath = req.file.path.replace(/\\/g, '/');

      // Update CMO with image path
      const cmo = await require('../models').CMO.findOne({
        where: { id: req.params.id, userId: req.userId }
      });

      if (!cmo) {
        return res.status(404).json({ success: false, message: 'CMO not found' });
      }

      await cmo.update({ oldMeterImagePath: filePath });

      res.json({
        success: true,
        message: 'Image uploaded successfully',
        data: { filePath }
      });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  }
);

router.post(
  '/:id/upload-seal-image',
  upload.single('sealImage'),
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({ success: false, message: 'No file uploaded' });
      }

      const filePath = req.file.path.replace(/\\/g, '/');
      const { sealType } = req.body; // 'battery' or 'terminal'

      const cmo = await require('../models').CMO.findOne({
        where: { id: req.params.id, userId: req.userId }
      });

      if (!cmo) {
        return res.status(404).json({ success: false, message: 'CMO not found' });
      }

      if (sealType === 'battery') {
        await cmo.update({ batteryCoverSealImagePath: filePath });
      } else if (sealType === 'terminal') {
        await cmo.update({ terminalCoverSealImagePath: filePath });
      } else {
        return res.status(400).json({ success: false, message: 'Invalid seal type' });
      }

      res.json({
        success: true,
        message: 'Seal image uploaded successfully',
        data: { filePath }
      });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  }
);

module.exports = router;
