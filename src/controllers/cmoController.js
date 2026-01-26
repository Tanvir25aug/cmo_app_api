const cmoService = require('../services/cmoService');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/response');
const logger = require('../utils/logger');

class CMOController {
  // Get all CMOs
  async getAll(req, res) {
    try {
      const result = await cmoService.getAllCMOs(req.userId, req.query);
      return paginatedResponse(res, result.cmos, result.pagination, 'CMOs retrieved successfully');
    } catch (error) {
      logger.error(`Get CMOs error: ${error.message}`);
      return errorResponse(res, error.message, 400);
    }
  }

  // Get single CMO
  async getById(req, res) {
    try {
      const cmo = await cmoService.getCMOById(req.params.id, req.userId);
      return successResponse(res, cmo, 'CMO retrieved successfully');
    } catch (error) {
      logger.error(`Get CMO error: ${error.message}`);
      return errorResponse(res, error.message, 404);
    }
  }

  // Create CMO
  async create(req, res) {
    try {
      const cmo = await cmoService.createCMO(req.userId, req.body);
      logger.info(`CMO created: ${cmo.id} by user ${req.userId}`);
      return successResponse(res, cmo, 'CMO created successfully', 201);
    } catch (error) {
      logger.error(`Create CMO error: ${error.message}`);
      return errorResponse(res, error.message, 400);
    }
  }

  // Update CMO
  async update(req, res) {
    try {
      const cmo = await cmoService.updateCMO(req.params.id, req.userId, req.body);
      logger.info(`CMO updated: ${cmo.id} by user ${req.userId}`);
      return successResponse(res, cmo, 'CMO updated successfully');
    } catch (error) {
      logger.error(`Update CMO error: ${error.message}`);
      return errorResponse(res, error.message, 400);
    }
  }

  // Delete CMO
  async delete(req, res) {
    try {
      const result = await cmoService.deleteCMO(req.params.id, req.userId);
      logger.info(`CMO deleted: ${req.params.id} by user ${req.userId}`);
      return successResponse(res, result, 'CMO deleted successfully');
    } catch (error) {
      logger.error(`Delete CMO error: ${error.message}`);
      return errorResponse(res, error.message, 404);
    }
  }

  // Sync CMOs (bulk upload from mobile)
  async sync(req, res) {
    try {
      const { cmos } = req.body;

      if (!Array.isArray(cmos)) {
        return errorResponse(res, 'CMOs must be an array', 400);
      }

      const result = await cmoService.syncCMOs(req.userId, cmos);
      logger.info(`Sync completed: ${result.success.length} succeeded, ${result.failed.length} failed`);
      return successResponse(res, result, 'Sync completed');
    } catch (error) {
      logger.error(`Sync error: ${error.message}`);
      return errorResponse(res, error.message, 400);
    }
  }

  // Get unsynced CMOs (download to mobile)
  async getUnsynced(req, res) {
    try {
      const { lastSyncDate } = req.query;
      const cmos = await cmoService.getUnsyncedCMOs(req.userId, lastSyncDate);
      return successResponse(res, cmos, 'Unsynced CMOs retrieved');
    } catch (error) {
      logger.error(`Get unsynced CMOs error: ${error.message}`);
      return errorResponse(res, error.message, 400);
    }
  }

  // Get statistics
  async getStatistics(req, res) {
    try {
      const stats = await cmoService.getStatistics(req.userId);
      return successResponse(res, stats, 'Statistics retrieved successfully');
    } catch (error) {
      logger.error(`Get statistics error: ${error.message}`);
      return errorResponse(res, error.message, 400);
    }
  }
}

module.exports = new CMOController();
