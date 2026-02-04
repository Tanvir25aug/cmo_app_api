const AppVersion = require('../models/AppVersion');
const path = require('path');
const fs = require('fs').promises;

// Get all versions
const getAllVersions = async (includeInactive = false) => {
  const where = includeInactive ? {} : { IsActive: 1 };

  const versions = await AppVersion.findAll({
    where,
    order: [['VersionCode', 'DESC']]
  });

  return versions;
};

// Get latest version
const getLatestVersion = async () => {
  const version = await AppVersion.findOne({
    where: { IsActive: 1 },
    order: [['VersionCode', 'DESC']]
  });

  return version;
};

// Get version by ID
const getVersionById = async (id) => {
  const version = await AppVersion.findByPk(id);
  if (!version) {
    throw new Error('Version not found');
  }
  return version;
};

// Create new version
const createVersion = async (versionData, file, uploadedBy) => {
  // Validate version code is higher than existing
  const latestVersion = await getLatestVersion();
  if (latestVersion && versionData.versionCode <= latestVersion.VersionCode) {
    throw new Error(`Version code must be greater than ${latestVersion.VersionCode}`);
  }

  // Create uploads/apk directory if not exists
  const apkDir = path.join(__dirname, '../../uploads/apk');
  try {
    await fs.mkdir(apkDir, { recursive: true });
  } catch (err) {
    // Directory already exists
  }

  // Generate unique filename
  const fileName = `cmo_app_v${versionData.versionName}_${Date.now()}.apk`;
  const filePath = path.join(apkDir, fileName);

  // Move uploaded file
  await fs.rename(file.path, filePath);

  // Get file size
  const stats = await fs.stat(filePath);

  // Create version record
  const version = await AppVersion.create({
    VersionCode: versionData.versionCode,
    VersionName: versionData.versionName,
    FileName: fileName,
    FilePath: `/uploads/apk/${fileName}`,
    FileSize: stats.size,
    ReleaseNotes: versionData.releaseNotes || '',
    IsMandatory: versionData.isMandatory ? 1 : 0,
    IsActive: 1,
    DownloadCount: 0,
    UploadedBy: uploadedBy,
    CreatedAt: new Date(),
    UpdatedAt: new Date()
  });

  return version;
};

// Update version
const updateVersion = async (id, updates) => {
  const version = await getVersionById(id);

  await version.update({
    ...updates,
    UpdatedAt: new Date()
  });

  return version;
};

// Deactivate version
const deactivateVersion = async (id) => {
  const version = await getVersionById(id);
  await version.update({ IsActive: 0, UpdatedAt: new Date() });
  return version;
};

// Delete version
const deleteVersion = async (id) => {
  const version = await getVersionById(id);

  // Delete file
  const filePath = path.join(__dirname, '../..', version.FilePath);
  try {
    await fs.unlink(filePath);
  } catch (err) {
    console.error('Error deleting file:', err.message);
  }

  await version.destroy();
  return { message: 'Version deleted successfully' };
};

// Increment download count
const incrementDownloadCount = async (id) => {
  const version = await getVersionById(id);
  await version.update({
    DownloadCount: version.DownloadCount + 1
  });
  return version;
};

// Check for update
const checkForUpdate = async (currentVersionCode) => {
  const latestVersion = await getLatestVersion();

  if (!latestVersion) {
    return { updateAvailable: false };
  }

  const updateAvailable = latestVersion.VersionCode > currentVersionCode;

  return {
    updateAvailable,
    currentVersion: currentVersionCode,
    latestVersion: updateAvailable ? {
      versionCode: latestVersion.VersionCode,
      versionName: latestVersion.VersionName,
      releaseNotes: latestVersion.ReleaseNotes,
      isMandatory: latestVersion.IsMandatory === 1,
      downloadUrl: latestVersion.FilePath,
      fileSize: latestVersion.FileSize
    } : null
  };
};

// Format file size
const formatFileSize = (bytes) => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
};

module.exports = {
  getAllVersions,
  getLatestVersion,
  getVersionById,
  createVersion,
  updateVersion,
  deactivateVersion,
  deleteVersion,
  incrementDownloadCount,
  checkForUpdate,
  formatFileSize
};
