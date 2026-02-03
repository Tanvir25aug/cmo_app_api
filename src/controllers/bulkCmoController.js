const bulkCmoService = require('../services/bulkCmoService');
const { successResponse, errorResponse } = require('../utils/response');

class BulkCmoController {
  /**
   * POST /cmo/bulk-sync
   * Bulk sync multiple CMOs in one request
   */
  async bulkSync(req, res) {
    try {
      const userId = req.userId;
      const securityId = req.securityId;
      const bulkData = req.body;

      if (!bulkData.CMOs || !Array.isArray(bulkData.CMOs)) {
        return errorResponse(res, 'CMOs array is required', 400);
      }

      if (bulkData.CMOs.length === 0) {
        return errorResponse(res, 'CMOs array cannot be empty', 400);
      }

      if (bulkData.CMOs.length > 50) {
        return errorResponse(res, 'Maximum 50 CMOs allowed per bulk sync', 400);
      }

      const results = await bulkCmoService.bulkSyncCMOs(userId, securityId, bulkData);

      const message = results.failedCount === 0
        ? `All ${results.successCount} CMOs synced successfully`
        : `${results.successCount} synced, ${results.failedCount} failed`;

      return successResponse(res, results, message);

    } catch (error) {
      console.error('Bulk sync error:', error);
      return errorResponse(res, 'Bulk sync failed: ' + error.message, 500);
    }
  }

  /**
   * GET /cmo/bulk-stats
   * Get bulk sync statistics
   */
  async getBulkStats(req, res) {
    try {
      const stats = await bulkCmoService.getBulkSyncStats();
      return successResponse(res, stats, 'Bulk stats retrieved successfully');
    } catch (error) {
      console.error('Bulk stats error:', error);
      return errorResponse(res, 'Failed to get bulk stats', 500);
    }
  }
}

module.exports = new BulkCmoController();
