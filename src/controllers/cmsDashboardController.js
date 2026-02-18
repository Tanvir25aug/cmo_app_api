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

      // Enrich rows with Customer data from MSSQL
      const DB_NAME = process.env.DB_NAME || 'MeterOCRDPDC';
      const plainRows = rows.map(r => r.get({ plain: true }));
      const customerIds = [...new Set(
        plainRows.map(r => r.CustomerId).filter(id => id != null && String(id).trim() !== '')
      )];

      let customerMap = {};
      if (customerIds.length > 0) {
        const chunkSize = 500;
        for (let i = 0; i < customerIds.length; i += chunkSize) {
          const chunk = customerIds.slice(i, i + chunkSize);
          const placeholders = chunk.map((_, idx) => `:id${idx}`).join(',');
          const replacements = {};
          chunk.forEach((id, idx) => { replacements[`id${idx}`] = id; });

          const results = await sequelize.query(`
            SELECT [OLD_CONSUMER_ID], [CUSTOMER_NAME], [ADDRESS], [MOBILE_NO],
                   [CHANGED_MOBILE_NO], [SECONDARY_MOBILE_NO], [NOCS]
            FROM [${DB_NAME}].[dbo].[Customer]
            WHERE [OLD_CONSUMER_ID] IN (${placeholders})
          `, { replacements, type: sequelize.QueryTypes.SELECT });

          results.forEach(c => { customerMap[c.OLD_CONSUMER_ID] = c; });
        }
      }

      const enrichedRows = plainRows.map(row => {
        const cust = customerMap[row.CustomerId] || {};
        return {
          ...row,
          CustomerName: cust.CUSTOMER_NAME || null,
          Address: cust.ADDRESS || null,
          MobileNo: cust.MOBILE_NO || null,
          ChangedMobileNo: cust.CHANGED_MOBILE_NO || null,
          SecondaryMobileNo: cust.SECONDARY_MOBILE_NO || null,
          NOCS: cust.NOCS || null
        };
      });

      return paginatedResponse(res, enrichedRows, {
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
   * POST /api/cmo/check-mdm-entry
   * Check all CMO records against Customer table and update IsMDMEntry
   * For records where IsMDMEntry = 0 or null, check if CustomerId exists
   * in Customer table's OLD_CONSUMER_ID. If found, set IsMDMEntry = 1.
   */
  async checkMDMEntry(req, res) {
    try {
      const DB_NAME = process.env.DB_NAME || 'MeterOCRDPDC';

      // Get all active MeterInfo records where IsMDMEntry is 0 or null
      const uncheckedRecords = await MeterInfo.findAll({
        where: {
          IsActive: 1,
          [Op.or]: [
            { IsMDMEntry: 0 },
            { IsMDMEntry: null }
          ]
        },
        attributes: ['Id', 'CustomerId']
      });

      if (uncheckedRecords.length === 0) {
        return successResponse(res, {
          checked: 0,
          updated: 0,
          message: 'No unchecked records found'
        }, 'MDM Entry check completed - no records to check');
      }

      // Get unique CustomerIds (filter out nulls/empties)
      const customerIds = [...new Set(
        uncheckedRecords
          .map(r => r.CustomerId)
          .filter(id => id != null && String(id).trim() !== '')
          .map(id => String(id).trim())
      )];

      if (customerIds.length === 0) {
        return successResponse(res, {
          checked: uncheckedRecords.length,
          updated: 0,
          message: 'No valid Customer IDs to check'
        }, 'MDM Entry check completed - no valid Customer IDs');
      }

      // Batch check against Customer table using raw SQL
      // Process in chunks of 500 to avoid query size limits
      const foundCustomerIds = new Set();
      const chunkSize = 500;

      for (let i = 0; i < customerIds.length; i += chunkSize) {
        const chunk = customerIds.slice(i, i + chunkSize);
        const placeholders = chunk.map((_, idx) => `:id${idx}`).join(',');
        const replacements = {};
        chunk.forEach((id, idx) => { replacements[`id${idx}`] = id; });

        const query = `
          SELECT DISTINCT [OLD_CONSUMER_ID]
          FROM [${DB_NAME}].[dbo].[Customer]
          WHERE [OLD_CONSUMER_ID] IN (${placeholders})
        `;

        const results = await sequelize.query(query, {
          replacements,
          type: sequelize.QueryTypes.SELECT
        });

        results.forEach(r => foundCustomerIds.add(r.OLD_CONSUMER_ID));
      }

      // Update matching records to IsMDMEntry = 1
      let updatedCount = 0;
      if (foundCustomerIds.size > 0) {
        const idsToUpdate = uncheckedRecords
          .filter(r => r.CustomerId != null && foundCustomerIds.has(String(r.CustomerId).trim()))
          .map(r => r.Id);

        if (idsToUpdate.length > 0) {
          // Update in chunks
          for (let i = 0; i < idsToUpdate.length; i += chunkSize) {
            const chunk = idsToUpdate.slice(i, i + chunkSize);
            const [affectedCount] = await MeterInfo.update(
              { IsMDMEntry: 1 },
              { where: { Id: { [Op.in]: chunk } } }
            );
            updatedCount += affectedCount;
          }
        }
      }

      logger.info(`MDM Entry check: checked ${uncheckedRecords.length}, found ${foundCustomerIds.size} in Customer DB, updated ${updatedCount} records`);

      return successResponse(res, {
        checked: uncheckedRecords.length,
        foundInCustomerDB: foundCustomerIds.size,
        updated: updatedCount
      }, `MDM Entry check completed. ${updatedCount} records updated.`);

    } catch (error) {
      logger.error(`CMS Dashboard checkMDMEntry error: ${error.message}`);
      return errorResponse(res, error.message, 500);
    }
  }

  /**
   * GET /api/cmo/unchecked-mdm
   * Returns all active MeterInfo records where IsMDMEntry is 0 or null
   * Only returns Id, CustomerId, NewMeterNoOCR for lightweight transfer
   */
  async getUncheckedMDM(req, res) {
    try {
      const records = await MeterInfo.findAll({
        where: {
          IsActive: 1,
          [Op.or]: [
            { IsMDMEntry: 0 },
            { IsMDMEntry: null }
          ]
        },
        attributes: ['Id', 'CustomerId', 'NewMeterNoOCR']
      });

      return successResponse(res, records, `Found ${records.length} unchecked MDM records`);
    } catch (error) {
      logger.error(`getUncheckedMDM error: ${error.message}`);
      return errorResponse(res, error.message, 500);
    }
  }

  /**
   * POST /api/cmo/bulk-update-mdm
   * Accepts { ids: [1,2,3...] } and sets IsMDMEntry = 1 for those IDs
   * Processes in chunks of 500 to avoid query size limits
   */
  async bulkUpdateMDM(req, res) {
    try {
      const { ids } = req.body;

      if (!ids || !Array.isArray(ids) || ids.length === 0) {
        return errorResponse(res, 'ids array is required and must not be empty', 400);
      }

      let updatedCount = 0;
      const chunkSize = 500;

      for (let i = 0; i < ids.length; i += chunkSize) {
        const chunk = ids.slice(i, i + chunkSize);
        const [affectedCount] = await MeterInfo.update(
          { IsMDMEntry: 1 },
          { where: { Id: { [Op.in]: chunk } } }
        );
        updatedCount += affectedCount;
      }

      logger.info(`bulkUpdateMDM: updated ${updatedCount} of ${ids.length} requested records`);

      return successResponse(res, { updated: updatedCount }, `Updated ${updatedCount} records`);
    } catch (error) {
      logger.error(`bulkUpdateMDM error: ${error.message}`);
      return errorResponse(res, error.message, 500);
    }
  }

  /**
   * GET /api/cmo/cms-export
   * Export all active MeterInfo records joined with Customer data
   * Supports optional search and isApproved query params
   */
  async getExportData(req, res) {
    try {
      const { search, isApproved } = req.query;
      const DB_NAME = process.env.DB_NAME || 'MeterOCRDPDC';

      let whereClauses = ['m.IsActive = 1'];
      const replacements = {};

      if (isApproved !== undefined && isApproved !== '') {
        whereClauses.push('m.IsApproved = :isApproved');
        replacements.isApproved = parseInt(isApproved);
      }

      if (search) {
        whereClauses.push(`(m.CustomerId LIKE :search OR m.OldConsumerId LIKE :search OR m.NewMeterNoOCR LIKE :search OR m.OldMeterNoOCR LIKE :search OR m.MeterInstalledBy LIKE :search)`);
        replacements.search = `%${search}%`;
      }

      const whereSQL = whereClauses.join(' AND ');

      const query = `
        SELECT m.CustomerId, c.CUSTOMER_NAME, c.ADDRESS, c.MOBILE_NO,
               c.CHANGED_MOBILE_NO, c.SECONDARY_MOBILE_NO, c.NOCS,
               m.InstallDate, m.NewMeterNoOCR, m.Latitude, m.Longitude
        FROM [${DB_NAME}].[dbo].[MeterInfo_test] m
        LEFT JOIN [${DB_NAME}].[dbo].[Customer] c ON m.CustomerId = c.OLD_CONSUMER_ID
        WHERE ${whereSQL}
        ORDER BY m.CreateDate DESC
      `;

      const results = await sequelize.query(query, {
        replacements,
        type: sequelize.QueryTypes.SELECT
      });

      return successResponse(res, results, `Export data retrieved: ${results.length} records`);
    } catch (error) {
      logger.error(`CMS Dashboard getExportData error: ${error.message}`);
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
