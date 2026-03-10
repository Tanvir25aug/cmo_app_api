const { AppVersion } = require('../models');

// In-memory cache to avoid a DB hit on every request
let _cachedVersion = null;
let _cacheTime = 0;
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes

/**
 * Middleware: block requests from outdated app versions.
 *
 * The Flutter app must send:
 *   X-App-Version-Code : integer build number  (e.g. 10)
 *   X-App-Version-Name : human-readable string (e.g. 1.3.2)
 *
 * If the version code is lower than the latest active version in AppVersions,
 * the request is rejected with HTTP 426 Upgrade Required.
 *
 * Requests that do NOT include X-App-Version-Code are passed through
 * (admin web dashboard, Postman, etc.).
 */
const checkAppVersion = async (req, res, next) => {
  const headerCode = req.header('X-App-Version-Code');

  // No header → not a mobile app request, allow through
  if (!headerCode) return next();

  const clientCode = parseInt(headerCode, 10);
  if (isNaN(clientCode)) return next();

  try {
    const now = Date.now();

    // Refresh cache if stale
    if (!_cachedVersion || (now - _cacheTime) > CACHE_TTL) {
      _cachedVersion = await AppVersion.findOne({
        where: { IsActive: 1 },
        order: [['VersionCode', 'DESC']],
      });
      _cacheTime = now;
    }

    // No version record in DB → allow all
    if (!_cachedVersion) return next();

    if (clientCode < _cachedVersion.VersionCode) {
      const clientName = req.header('X-App-Version-Name') || String(clientCode);
      return res.status(426).json({
        success: false,
        updateRequired: true,
        message: `আপনার অ্যাপ ভার্সন (${clientName}) পুরানো। সিঙ্ক ও ডেটা ফেচ করতে ভার্সন ${_cachedVersion.VersionName} আপডেট করুন।`,
        messageEn: `App version ${clientName} is outdated. Please update to v${_cachedVersion.VersionName} to sync and fetch data.`,
        data: {
          requiredVersionCode: _cachedVersion.VersionCode,
          requiredVersionName: _cachedVersion.VersionName,
        },
      });
    }

    next();
  } catch (err) {
    // Never block on version-check failure — log and continue
    console.error('Version check error:', err.message);
    next();
  }
};

// Call this when a new APK is uploaded so the cache refreshes immediately
const invalidateVersionCache = () => {
  _cachedVersion = null;
  _cacheTime = 0;
};

module.exports = { checkAppVersion, invalidateVersionCache };
