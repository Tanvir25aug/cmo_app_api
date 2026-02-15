const { MeterInfo, AdminSecurity } = require('../models');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/response');
const { Op } = require('sequelize');
const { sequelize } = require('../config/database');
const logger = require('../utils/logger');

class CMSDashboardController {
  /**
   * GET /api/cmo/cms-list
   * List all MeterInfo records with pagination, search, and filters
   * Used by CMS dashboard to display all CMO data
   */
  async getAll(req, res) {
    try {
      const {
        page = 1,
        limit = 20,
        search,
        sortBy = 'CreateDate',
        sortOrder = 'DESC',
        isApproved
      } = req.query;

      const offset = (parseInt(page) - 1) * parseInt(limit);

      // Build where clause - only active records
      const where = { IsActive: 1 };

      if (isApproved !== undefined && isApproved !== '') {
        where.IsApproved = parseInt(isApproved);
      }

      if (search) {
        where[Op.or] = [
          { CustomerId: { [Op.like]: `%${search}%` } },
          { OldConsumerId: { [Op.like]: `%${search}%` } },
          { NewMeterNoOCR: { [Op.like]: `%${search}%` } },
          { OldMeterNoOCR: { [Op.like]: `%${search}%` } },
          { MeterInstalledBy: { [Op.like]: `%${search}%` } }
        ];
      }

      // Map sortBy to actual column names
      const sortMap = {
        'createdAt': 'CreateDate',
        'CreateDate': 'CreateDate',
        'customerId': 'CustomerId',
        'CustomerId': 'CustomerId',
        'installDate': 'InstallDate',
        'InstallDate': 'InstallDate'
      };

      const actualSortBy = sortMap[sortBy] || 'CreateDate';

      const { count, rows } = await MeterInfo.findAndCountAll({
        where,
        limit: parseInt(limit),
        offset,
        order: [[actualSortBy, sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC']],
        include: [{
          model: AdminSecurity,
          as: 'creator',
          attributes: ['SecurityId', 'UserId', 'UserName'],
          required: false
        }]
      });

      return paginatedResponse(res, rows, {
        total: count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(count / parseInt(limit))
      }, 'CMO records retrieved successfully');

    } catch (error) {
      logger.error(`CMS Dashboard getAll error: ${error.message}`);
      return errorResponse(res, error.message, 500);
    }
  }

  /**
   * GET /api/cmo/cms-statistics
   * Get statistics from MeterInfo_test for CMS dashboard
   */
  async getStatistics(req, res) {
    try {
      const total = await MeterInfo.count({ where: { IsActive: 1 } });
      const approved = await MeterInfo.count({ where: { IsActive: 1, IsApproved: 1 } });
      const pending = await MeterInfo.count({ where: { IsActive: 1, IsApproved: 0 } });
      const hasRevisit = await MeterInfo.count({ where: { IsActive: 1, HasRevisit: 1 } });
      const mdmEntry = await MeterInfo.count({ where: { IsActive: 1, IsMDMEntry: 1 } });

      return successResponse(res, {
        total,
        approved,
        pending,
        hasRevisit,
        mdmEntry
      }, 'Statistics retrieved successfully');

    } catch (error) {
      logger.error(`CMS Dashboard statistics error: ${error.message}`);
      return errorResponse(res, error.message, 500);
    }
  }
}

module.exports = new CMSDashboardController();
