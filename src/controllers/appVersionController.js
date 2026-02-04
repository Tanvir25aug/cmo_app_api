const appVersionService = require('../services/appVersionService');
const { success, error } = require('../utils/response');
const path = require('path');
const fs = require('fs');

class AppVersionController {
  constructor() {
    // Bind all methods to ensure proper 'this' context
    this.getAllVersions = this.getAllVersions.bind(this);
    this.getLatestVersion = this.getLatestVersion.bind(this);
    this.uploadVersion = this.uploadVersion.bind(this);
    this.downloadApk = this.downloadApk.bind(this);
    this.downloadLatest = this.downloadLatest.bind(this);
    this.checkForUpdate = this.checkForUpdate.bind(this);
    this.updateVersion = this.updateVersion.bind(this);
    this.deleteVersion = this.deleteVersion.bind(this);
  }

  // Get all versions
  async getAllVersions(req, res) {
    try {
      const includeInactive = req.query.all === 'true';
      const versions = await appVersionService.getAllVersions(includeInactive);

      return success(res, 'Versions retrieved successfully', {
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
      });
    } catch (err) {
      return error(res, err.message, 500);
    }
  }

  // Get latest version
  async getLatestVersion(req, res) {
    try {
      const version = await appVersionService.getLatestVersion();

      if (!version) {
        return error(res, 'No version available', 404);
      }

      return success(res, 'Latest version retrieved', {
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
      });
    } catch (err) {
      return error(res, err.message, 500);
    }
  }

  // Upload new version
  async uploadVersion(req, res) {
    try {
      if (!req.file) {
        return error(res, 'APK file is required', 400);
      }

      const { versionCode, versionName, releaseNotes, isMandatory } = req.body;

      if (!versionCode || !versionName) {
        return error(res, 'Version code and version name are required', 400);
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

      return success(res, 'Version uploaded successfully', {
        version: {
          id: version.Id,
          versionCode: version.VersionCode,
          versionName: version.VersionName,
          fileName: version.FileName,
          filePath: version.FilePath,
          fileSize: version.FileSize,
          fileSizeFormatted: appVersionService.formatFileSize(version.FileSize)
        }
      }, 201);
    } catch (err) {
      // Clean up uploaded file if error
      if (req.file && req.file.path) {
        try {
          fs.unlinkSync(req.file.path);
        } catch (e) {}
      }
      return error(res, err.message, 400);
    }
  }

  // Download APK
  async downloadApk(req, res) {
    try {
      const { id } = req.params;
      const version = await appVersionService.getVersionById(id);

      // Increment download count
      await appVersionService.incrementDownloadCount(id);

      const filePath = path.join(__dirname, '../..', version.FilePath);

      if (!fs.existsSync(filePath)) {
        return error(res, 'File not found', 404);
      }

      res.download(filePath, version.FileName);
    } catch (err) {
      return error(res, err.message, 500);
    }
  }

  // Download latest APK
  async downloadLatest(req, res) {
    try {
      const version = await appVersionService.getLatestVersion();

      if (!version) {
        return error(res, 'No version available', 404);
      }

      // Increment download count
      await appVersionService.incrementDownloadCount(version.Id);

      const filePath = path.join(__dirname, '../..', version.FilePath);

      if (!fs.existsSync(filePath)) {
        return error(res, 'File not found', 404);
      }

      res.download(filePath, version.FileName);
    } catch (err) {
      return error(res, err.message, 500);
    }
  }

  // Check for update
  async checkForUpdate(req, res) {
    try {
      const { versionCode } = req.query;

      if (!versionCode) {
        return error(res, 'Current version code is required', 400);
      }

      const result = await appVersionService.checkForUpdate(parseInt(versionCode));

      return success(res, 'Update check completed', result);
    } catch (err) {
      return error(res, err.message, 500);
    }
  }

  // Update version info
  async updateVersion(req, res) {
    try {
      const { id } = req.params;
      const { releaseNotes, isMandatory, isActive } = req.body;

      const updates = {};
      if (releaseNotes !== undefined) updates.ReleaseNotes = releaseNotes;
      if (isMandatory !== undefined) updates.IsMandatory = isMandatory ? 1 : 0;
      if (isActive !== undefined) updates.IsActive = isActive ? 1 : 0;

      const version = await appVersionService.updateVersion(id, updates);

      return success(res, 'Version updated successfully', { version });
    } catch (err) {
      return error(res, err.message, 400);
    }
  }

  // Delete version
  async deleteVersion(req, res) {
    try {
      const { id } = req.params;
      const result = await appVersionService.deleteVersion(id);

      return success(res, result.message);
    } catch (err) {
      return error(res, err.message, 400);
    }
  }
}

module.exports = new AppVersionController();
