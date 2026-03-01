const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { auth } = require('../middleware/auth');

// Ensure upload directories exist
const tempUploadDir = path.join(__dirname, '../../uploads/temp');
const apkUploadDir = path.join(__dirname, '../../uploads/apk');
const chunksDir = path.join(__dirname, '../../uploads/chunks');
if (!fs.existsSync(tempUploadDir)) {
  fs.mkdirSync(tempUploadDir, { recursive: true });
}
if (!fs.existsSync(apkUploadDir)) {
  fs.mkdirSync(apkUploadDir, { recursive: true });
}
if (!fs.existsSync(chunksDir)) {
  fs.mkdirSync(chunksDir, { recursive: true });
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

// Load service (used by chunked upload complete handler)
let appVersionService;
try {
  appVersionService = require('../services/appVersionService');
  console.log('AppVersion service loaded successfully');
} catch (err) {
  console.error('Failed to load appVersionService:', err.message);
  appVersionService = null;
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

// ============ CHUNKED UPLOAD ROUTES ============

// Use memory storage for chunks, then save manually (uploadId available in query params)
const chunkUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 2 * 1024 * 1024 } // 2MB per chunk
});

// Initialize chunked upload
router.post('/upload/init', auth, (req, res) => {
  try {
    const { fileName, fileSize, totalChunks, versionCode, versionName, releaseNotes, isMandatory } = req.body;

    if (!fileName || !fileSize || !totalChunks || !versionCode || !versionName) {
      return res.status(400).json({ success: false, message: 'Missing required fields' });
    }

    const uploadId = `upload_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const uploadDir = path.join(chunksDir, uploadId);
    fs.mkdirSync(uploadDir, { recursive: true });

    // Store metadata
    const metadata = { fileName, fileSize, totalChunks, versionCode, versionName, releaseNotes, isMandatory, uploadedChunks: [] };
    fs.writeFileSync(path.join(uploadDir, 'metadata.json'), JSON.stringify(metadata));

    console.log(`[CHUNKED] Upload initialized: ${uploadId}, ${totalChunks} chunks expected`);
    res.json({ success: true, message: 'Upload initialized', data: { uploadId, totalChunks } });
  } catch (err) {
    console.error('[CHUNKED] Init error:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});

// Upload a chunk - use query params since they're available before multer parses body
router.post('/upload/chunk', auth, chunkUpload.single('chunk'), (req, res) => {
  try {
    // Get from query params (available before body parsing)
    const uploadId = req.query.uploadId || req.body.uploadId;
    const chunkIndex = req.query.chunkIndex !== undefined ? req.query.chunkIndex : req.body.chunkIndex;

    if (!uploadId || chunkIndex === undefined) {
      return res.status(400).json({ success: false, message: 'Missing uploadId or chunkIndex' });
    }

    const uploadDir = path.join(chunksDir, uploadId);
    const metadataPath = path.join(uploadDir, 'metadata.json');

    if (!fs.existsSync(metadataPath)) {
      return res.status(400).json({ success: false, message: 'Invalid upload ID' });
    }

    // Save chunk from memory to disk
    if (!req.file || !req.file.buffer) {
      return res.status(400).json({ success: false, message: 'No chunk data received' });
    }

    const chunkPath = path.join(uploadDir, `chunk_${chunkIndex}`);
    fs.writeFileSync(chunkPath, req.file.buffer);

    // Update metadata
    const metadata = JSON.parse(fs.readFileSync(metadataPath, 'utf8'));
    if (!metadata.uploadedChunks.includes(parseInt(chunkIndex))) {
      metadata.uploadedChunks.push(parseInt(chunkIndex));
    }
    fs.writeFileSync(metadataPath, JSON.stringify(metadata));

    console.log(`[CHUNKED] Chunk ${chunkIndex}/${metadata.totalChunks - 1} received for ${uploadId}`);
    res.json({
      success: true,
      message: 'Chunk uploaded',
      data: {
        chunkIndex: parseInt(chunkIndex),
        uploadedChunks: metadata.uploadedChunks.length,
        totalChunks: metadata.totalChunks
      }
    });
  } catch (err) {
    console.error('[CHUNKED] Chunk error:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});

// Complete chunked upload - assemble chunks
router.post('/upload/complete', auth, async (req, res) => {
  try {
    const { uploadId } = req.body;

    if (!uploadId) {
      return res.status(400).json({ success: false, message: 'Missing uploadId' });
    }

    const uploadDir = path.join(chunksDir, uploadId);
    const metadataPath = path.join(uploadDir, 'metadata.json');

    if (!fs.existsSync(metadataPath)) {
      return res.status(400).json({ success: false, message: 'Invalid upload ID' });
    }

    const metadata = JSON.parse(fs.readFileSync(metadataPath, 'utf8'));

    // Check all chunks uploaded
    if (metadata.uploadedChunks.length !== metadata.totalChunks) {
      return res.status(400).json({
        success: false,
        message: `Missing chunks. Expected ${metadata.totalChunks}, got ${metadata.uploadedChunks.length}`
      });
    }

    console.log(`[CHUNKED] Assembling ${metadata.totalChunks} chunks for ${uploadId}`);

    // Assemble chunks
    const finalFileName = `cmo_app_v${metadata.versionName}_${Date.now()}.apk`;
    const finalPath = path.join(apkUploadDir, finalFileName);
    const writeStream = fs.createWriteStream(finalPath);

    for (let i = 0; i < metadata.totalChunks; i++) {
      const chunkPath = path.join(uploadDir, `chunk_${i}`);
      const chunkData = fs.readFileSync(chunkPath);
      writeStream.write(chunkData);
    }
    writeStream.end();

    // Wait for write to complete
    await new Promise((resolve, reject) => {
      writeStream.on('finish', resolve);
      writeStream.on('error', reject);
    });

    // Get final file size
    const stats = fs.statSync(finalPath);
    console.log(`[CHUNKED] File assembled: ${finalFileName} (${stats.size} bytes)`);

    // Save to DB using the service (runs version-code validation + correct INSERT logic)
    console.log(`[CHUNKED] Saving to DB: version ${metadata.versionCode} (${metadata.versionName})`);
    let newVersion;
    try {
      if (!appVersionService) {
        throw new Error('appVersionService not available — check server logs for load errors');
      }
      newVersion = await appVersionService.createVersion(
        {
          versionCode: parseInt(metadata.versionCode),
          versionName: metadata.versionName,
          releaseNotes: metadata.releaseNotes || '',
          isMandatory: metadata.isMandatory === 'true' || metadata.isMandatory === true
        },
        { path: finalPath },          // mock multer file — service will rename it
        req.securityId || null        // UploadedBy (SecurityId from auth middleware)
      );
      console.log(`[CHUNKED] DB record created: Id=${newVersion.Id}`);
    } catch (dbError) {
      // File assembled on disk but DB failed — clean up the assembled file
      try { fs.unlinkSync(finalPath); } catch (_) {}
      console.error(`[CHUNKED] DB error: ${dbError.message}`);
      throw dbError;  // Re-throw so outer catch returns 500 with clear message
    }

    // Cleanup chunks only after successful DB insert
    fs.rmSync(uploadDir, { recursive: true, force: true });

    console.log(`[CHUNKED] Upload complete: ${newVersion.FileName}`);
    res.json({
      success: true,
      message: 'APK uploaded and version record saved successfully',
      data: {
        id: newVersion.Id,
        fileName: newVersion.FileName,
        fileSize: newVersion.FileSize,
        versionCode: newVersion.VersionCode,
        versionName: newVersion.VersionName
      }
    });
  } catch (err) {
    console.error('[CHUNKED] Complete error:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});

// ============ ORIGINAL UPLOAD ROUTE (kept for backward compatibility) ============

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
