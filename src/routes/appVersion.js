const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { auth } = require('../middleware/auth');

// Ensure upload directories exist
const tempUploadDir = path.join(__dirname, '../../uploads/temp');
const apkUploadDir = path.join(__dirname, '../../uploads/apk');
if (!fs.existsSync(tempUploadDir)) {
  fs.mkdirSync(tempUploadDir, { recursive: true });
}
if (!fs.existsSync(apkUploadDir)) {
  fs.mkdirSync(apkUploadDir, { recursive: true });
}

// Load controller with error handling
let appVersionController;
try {
  appVersionController = require('../controllers/appVersionController');
  console.log('AppVersion controller loaded successfully');
} catch (err) {
  console.error('Failed to load appVersionController:', err.message);
  appVersionController = {};
}

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

// Helper to create safe handler
const safeHandler = (handler, name) => {
  if (typeof handler === 'function') {
    return handler;
  }
  return (req, res) => {
    res.status(500).json({
      success: false,
      message: `Handler ${name} not available - module load error`
    });
  };
};

// Public routes (no auth required)
router.get('/versions', safeHandler(appVersionController.getAllVersions, 'getAllVersions'));
router.get('/latest', safeHandler(appVersionController.getLatestVersion, 'getLatestVersion'));
router.get('/check-update', safeHandler(appVersionController.checkForUpdate, 'checkForUpdate'));
router.get('/download/latest', safeHandler(appVersionController.downloadLatest, 'downloadLatest'));
router.get('/download/:id', safeHandler(appVersionController.downloadApk, 'downloadApk'));

// Middleware to extend timeout for uploads
const extendTimeout = (req, res, next) => {
  req.setTimeout(600000); // 10 minutes for upload
  res.setTimeout(600000);
  console.log('[UPLOAD] Request started, timeout extended');

  // Monitor connection for debugging
  req.on('close', () => {
    if (!res.writableEnded) {
      console.log('[UPLOAD] Connection closed by client before response');
    }
  });
  req.on('aborted', () => {
    console.log('[UPLOAD] Request aborted');
  });

  next();
};

// Protected routes (auth required)
router.post('/upload', extendTimeout, auth, (req, res, next) => {
  console.log('[UPLOAD] Auth passed, starting file upload...');
  upload.single('apk')(req, res, (err) => {
    if (err) {
      console.error('[UPLOAD] Multer error:', err.message);
      if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
          return res.status(400).json({ success: false, message: 'File too large. Maximum size is 200MB' });
        }
        return res.status(400).json({ success: false, message: `Upload error: ${err.message}` });
      }
      return res.status(400).json({ success: false, message: err.message });
    }
    console.log('[UPLOAD] File received:', req.file ? req.file.originalname : 'No file');
    next();
  });
}, safeHandler(appVersionController.uploadVersion, 'uploadVersion'));
router.put('/:id', auth, safeHandler(appVersionController.updateVersion, 'updateVersion'));
router.delete('/:id', auth, safeHandler(appVersionController.deleteVersion, 'deleteVersion'));

module.exports = router;
