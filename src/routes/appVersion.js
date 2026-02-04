const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const appVersionController = require('../controllers/appVersionController');
const { authenticate, isAdmin } = require('../middleware/auth');

// Configure multer for APK uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, path.join(__dirname, '../../uploads/temp'));
  },
  filename: function (req, file, cb) {
    cb(null, `temp_${Date.now()}_${file.originalname}`);
  }
});

const fileFilter = (req, file, cb) => {
  // Accept only APK files
  if (file.mimetype === 'application/vnd.android.package-archive' ||
      file.originalname.endsWith('.apk')) {
    cb(null, true);
  } else {
    cb(new Error('Only APK files are allowed'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 200 * 1024 * 1024 // 200MB limit
  }
});

// Public routes (no auth required)
router.get('/versions', appVersionController.getAllVersions);
router.get('/latest', appVersionController.getLatestVersion);
router.get('/check-update', appVersionController.checkForUpdate);
router.get('/download/latest', appVersionController.downloadLatest);
router.get('/download/:id', appVersionController.downloadApk);

// Protected routes (auth required)
router.post('/upload', authenticate, upload.single('apk'), appVersionController.uploadVersion);
router.put('/:id', authenticate, appVersionController.updateVersion);
router.delete('/:id', authenticate, appVersionController.deleteVersion);

module.exports = router;
