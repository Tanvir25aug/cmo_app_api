const { successResponse, errorResponse } = require('../utils/response');
const path = require('path');
const fs = require('fs');

// Load service with error handling
let appVersionService;
try {
  appVersionService = require('../services/appVersionService');
  console.log('AppVersion service loaded successfully');
} catch (err) {
  console.error('Failed to load appVersionService:', err.message);
  console.error(err.stack);
  appVersionService = null;
}

// Get all versions
const getAllVersions = async (req, res) => {
  try {
    if (!appVersionService) {
      return errorResponse(res, 'Service not available', 500);
    }
    const includeInactive = req.query.all === 'true';
    const versions = await appVersionService.getAllVersions(includeInactive);

    return successResponse(res, {
      versions: versions.map(v => ({
        id: v.Id,
        versionCode: v.VersionCode,
        versionName: v.VersionName,
        fileName: v.FileName,
        filePath: v.FilePath,
        fileSize: v.FileSize,
        fileSizeFormatted: appVersionService.formatFileSize(v.FileSize),
        releaseNotes: v.ReleaseNotes,
        isMandatory: v.IsMandatory === 1,
        isActive: v.IsActive === 1,
        downloadCount: v.DownloadCount,
        createdAt: v.CreatedAt
      }))
    }, 'Versions retrieved successfully');
  } catch (err) {
    return errorResponse(res, err.message, 500);
  }
};

// Get latest version
const getLatestVersion = async (req, res) => {
  try {
    if (!appVersionService) {
      return errorResponse(res, 'Service not available', 500);
    }
    const version = await appVersionService.getLatestVersion();

    if (!version) {
      return errorResponse(res, 'No version available', 404);
    }

    return successResponse(res, {
      version: {
        id: version.Id,
        versionCode: version.VersionCode,
        versionName: version.VersionName,
        fileName: version.FileName,
        filePath: version.FilePath,
        fileSize: version.FileSize,
        fileSizeFormatted: appVersionService.formatFileSize(version.FileSize),
        releaseNotes: version.ReleaseNotes,
        isMandatory: version.IsMandatory === 1,
        downloadCount: version.DownloadCount,
        createdAt: version.CreatedAt
      }
    }, 'Latest version retrieved');
  } catch (err) {
    return errorResponse(res, err.message, 500);
  }
};

// Upload new version
const uploadVersion = async (req, res) => {
  try {
    if (!appVersionService) {
      return errorResponse(res, 'Service not available', 500);
    }
    if (!req.file) {
      return errorResponse(res, 'APK file is required', 400);
    }

    const { versionCode, versionName, releaseNotes, isMandatory } = req.body;

    if (!versionCode || !versionName) {
      return errorResponse(res, 'Version code and version name are required', 400);
    }

    const version = await appVersionService.createVersion(
      {
        versionCode: parseInt(versionCode),
        versionName,
        releaseNotes,
        isMandatory: isMandatory === 'true' || isMandatory === '1'
      },
      req.file,
      req.user?.SecurityId || null
    );

    return successResponse(res, {
      version: {
        id: version.Id,
        versionCode: version.VersionCode,
        versionName: version.VersionName,
        fileName: version.FileName,
        filePath: version.FilePath,
        fileSize: version.FileSize,
        fileSizeFormatted: appVersionService.formatFileSize(version.FileSize)
      }
    }, 'Version uploaded successfully', 201);
  } catch (err) {
    // Clean up uploaded file if error
    if (req.file && req.file.path) {
      try {
        fs.unlinkSync(req.file.path);
      } catch (e) {}
    }
    return errorResponse(res, err.message, 400);
  }
};

// Download APK
const downloadApk = async (req, res) => {
  try {
    if (!appVersionService) {
      return errorResponse(res, 'Service not available', 500);
    }
    const { id } = req.params;
    const version = await appVersionService.getVersionById(id);

    // Increment download count
    await appVersionService.incrementDownloadCount(id);

    const filePath = path.join(__dirname, '../..', version.FilePath);

    if (!fs.existsSync(filePath)) {
      return errorResponse(res, 'File not found', 404);
    }

    res.download(filePath, version.FileName);
  } catch (err) {
    return errorResponse(res, err.message, 500);
  }
};

// Download latest APK
const downloadLatest = async (req, res) => {
  try {
    if (!appVersionService) {
      return errorResponse(res, 'Service not available', 500);
    }
    const version = await appVersionService.getLatestVersion();

    if (!version) {
      return errorResponse(res, 'No version available', 404);
    }

    // Increment download count
    await appVersionService.incrementDownloadCount(version.Id);

    const filePath = path.join(__dirname, '../..', version.FilePath);

    if (!fs.existsSync(filePath)) {
      return errorResponse(res, 'File not found', 404);
    }

    res.download(filePath, version.FileName);
  } catch (err) {
    return errorResponse(res, err.message, 500);
  }
};

// Check for update
const checkForUpdate = async (req, res) => {
  try {
    if (!appVersionService) {
      return errorResponse(res, 'Service not available', 500);
    }
    const { versionCode } = req.query;

    if (!versionCode) {
      return errorResponse(res, 'Current version code is required', 400);
    }

    const result = await appVersionService.checkForUpdate(parseInt(versionCode));

    return successResponse(res, result, 'Update check completed');
  } catch (err) {
    return errorResponse(res, err.message, 500);
  }
};

// Update version info
const updateVersion = async (req, res) => {
  try {
    if (!appVersionService) {
      return errorResponse(res, 'Service not available', 500);
    }
    const { id } = req.params;
    const { releaseNotes, isMandatory, isActive } = req.body;

    const updates = {};
    if (releaseNotes !== undefined) updates.ReleaseNotes = releaseNotes;
    if (isMandatory !== undefined) updates.IsMandatory = isMandatory ? 1 : 0;
    if (isActive !== undefined) updates.IsActive = isActive ? 1 : 0;

    const version = await appVersionService.updateVersion(id, updates);

    return successResponse(res, { version }, 'Version updated successfully');
  } catch (err) {
    return errorResponse(res, err.message, 400);
  }
};

// Delete version
const deleteVersion = async (req, res) => {
  try {
    if (!appVersionService) {
      return errorResponse(res, 'Service not available', 500);
    }
    const { id } = req.params;
    const result = await appVersionService.deleteVersion(id);

    return successResponse(res, {}, result.message);
  } catch (err) {
    return errorResponse(res, err.message, 400);
  }
};

module.exports = {
  getAllVersions,
  getLatestVersion,
  uploadVersion,
  downloadApk,
  downloadLatest,
  checkForUpdate,
  updateVersion,
  deleteVersion
};
