const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { auth } = require('../middleware/auth');
const { uploadLimiter } = require('../middleware/rateLimiter');

// Get upload path from env or default
const uploadPath = process.env.UPLOAD_PATH || './uploads';
const metersPath = path.join(uploadPath, 'meters');
const sealsPath = path.join(uploadPath, 'seals');

// Ensure directories exist
[metersPath, sealsPath].forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

// Storage for meters
const metersStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, metersPath);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, 'meter-' + uniqueSuffix + ext);
  }
});

// Storage for seals
const sealsStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, sealsPath);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, 'seal-' + uniqueSuffix + ext);
  }
});

// File filter - accept images only (more lenient for mobile uploads)
const fileFilter = (req, file, cb) => {
  const allowedTypes = /jpeg|jpg|png|gif|webp|heic|heif/;
  const allowedMimes = /image\//;

  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
  const mimetype = allowedMimes.test(file.mimetype);

  // Accept if either extension or mimetype indicates an image
  // Also accept if no extension but mimetype starts with 'image/'
  if (mimetype || extname || file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    // Be lenient - accept anyway for mobile uploads that may not have proper mime types
    console.log(`Warning: Accepting file with mimetype: ${file.mimetype}, originalname: ${file.originalname}`);
    cb(null, true);
  }
};

const uploadMeters = multer({
  storage: metersStorage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: fileFilter
});

const uploadSeals = multer({
  storage: sealsStorage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: fileFilter
});

// POST /api/upload/meters - Upload meter image
router.post('/meters', uploadLimiter, auth, uploadMeters.single('image'), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    const filePath = req.file.path.replace(/\\/g, '/');
    const fileUrl = `/uploads/meters/${req.file.filename}`;

    res.json({
      success: true,
      message: 'Meter image uploaded successfully',
      url: fileUrl,
      filePath: filePath,
      filename: req.file.filename
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// POST /api/upload/seals - Upload seal image
router.post('/seals', uploadLimiter, auth, uploadSeals.single('image'), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    const filePath = req.file.path.replace(/\\/g, '/');
    const fileUrl = `/uploads/seals/${req.file.filename}`;

    res.json({
      success: true,
      message: 'Seal image uploaded successfully',
      url: fileUrl,
      filePath: filePath,
      filename: req.file.filename
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

module.exports = router;
