const express = require('express');
const router = express.Router();
const cmoController = require('../controllers/cmoController');
const bulkCmoController = require('../controllers/bulkCmoController');
const cmsDashboardController = require('../controllers/cmsDashboardController');
const { auth } = require('../middleware/auth');
const { checkAppVersion } = require('../middleware/versionCheck');
const { upload } = require('../config/multer');
const { validateCMO } = require('../utils/validators');

// All routes require authentication
router.use(auth);

// ─── CMS Web Dashboard routes ────────────────────────────────────────────────
// These are called by the web browser/dashboard — NO version check applied.
// Must be declared before /:id to avoid route conflicts.
router.get('/cms-list',                 cmsDashboardController.getAll);
router.patch('/cms-list/:id/approval',  cmsDashboardController.updateApproval);
router.post('/cms-list/:id/approval',   cmsDashboardController.updateApproval); // Flutter uses POST
router.get('/cms-export',               cmsDashboardController.getExportData);
router.get('/cms-statistics',           cmsDashboardController.getStatistics);
router.get('/filter-options',           cmsDashboardController.getFilterOptions);
router.post('/check-mdm-entry',         cmsDashboardController.checkMDMEntry);
router.get('/unchecked-mdm',            cmsDashboardController.getUncheckedMDM);
router.post('/bulk-update-mdm',         cmsDashboardController.bulkUpdateMDM);
router.post('/upload-customers',        cmsDashboardController.uploadCustomers);

// ─── Mobile App routes ────────────────────────────────────────────────────────
// These are called by the Flutter app — version check IS enforced.
// App must send X-App-Version-Code header with a current version.
router.get('/',           checkAppVersion, cmoController.getAll);
router.get('/statistics', checkAppVersion, cmoController.getStatistics);
router.get('/unsynced',   checkAppVersion, cmoController.getUnsynced);
router.get('/bulk-stats', checkAppVersion, bulkCmoController.getBulkStats);
router.get('/:id',        checkAppVersion, cmoController.getById);

router.post('/',          checkAppVersion, validateCMO, cmoController.create);
router.post('/sync',      checkAppVersion, cmoController.sync);
router.post('/bulk-sync', checkAppVersion, bulkCmoController.bulkSync);

router.put('/:id',        checkAppVersion, validateCMO, cmoController.update);
router.delete('/:id',     checkAppVersion, cmoController.delete);

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
