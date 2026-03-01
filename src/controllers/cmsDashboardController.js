const { MeterInfo, AdminSecurity } = require('../models');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/response');
const { Op } = require('sequelize');
const { sequelize } = require('../config/database');
const logger = require('../utils/logger');

class CMSDashboardController {
  /**
   * GET /api/cmo/cms-list
   * List all MeterInfo_test records with pagination, search, and filters.
   * Uses a raw SQL JOIN with Customer + AdminSecurity tables so that
   * customer name, NOCS and installer name are available for filtering & display.
   *
   * Query params:
   *   page, limit          – pagination
   *   search               – searches OldConsumerId, NewMeterNoOCR, OldMeterNoOCR, CustomerName
   *   sortBy, sortOrder    – column name + ASC/DESC
   *   isApproved           – 0 or 1
   *   isMDMEntry           – 0 or 1
   *   hasRevisit           – 0 or 1
   *   nocs                 – partial match on Customer.NOCS
   *   dateFrom, dateTo     – InstallDate range (YYYY-MM-DD)
   *   installedBy          – partial match on AdminSecurity.UserName
   *   meterType            – exact match on NewMeterType (e.g. "1P", "3P")
   *   hasSteelBox          – 0 or 1
   */
  async getAll(req, res) {
    try {
      const {
        page = 1,
        limit = 20,
        search,
        sortBy = 'CreateDate',
        sortOrder = 'DESC',
        isApproved,
        isMDMEntry,
        hasRevisit,
        nocs,
        dateFrom,
        dateTo,
        installedBy,
        meterType,
        hasSteelBox,
      } = req.query;

      const offset = (parseInt(page) - 1) * parseInt(limit);
      const DB_NAME = process.env.DB_NAME || 'MeterOCRDPDC';

      // Whitelist sort columns to prevent SQL injection
      const allowedSort = ['CreateDate', 'InstallDate', 'OldConsumerId', 'NewMeterNoOCR', 'OldMeterNoOCR'];
      const actualSortBy = allowedSort.includes(sortBy) ? sortBy : 'CreateDate';
      const actualSortOrder = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

      // Build WHERE clauses dynamically
      const whereClauses = ['m.IsActive = 1'];
      const replacements = {};

      if (isApproved !== undefined && isApproved !== '') {
        whereClauses.push('m.IsApproved = :isApproved');
        replacements.isApproved = parseInt(isApproved);
      }
      if (isMDMEntry !== undefined && isMDMEntry !== '') {
        whereClauses.push('m.IsMDMEntry = :isMDMEntry');
        replacements.isMDMEntry = parseInt(isMDMEntry);
      }
      if (hasRevisit !== undefined && hasRevisit !== '') {
        whereClauses.push('m.HasRevisit = :hasRevisit');
        replacements.hasRevisit = parseInt(hasRevisit);
      }
      if (meterType !== undefined && meterType !== '') {
        whereClauses.push('m.NewMeterType = :meterType');
        replacements.meterType = meterType;
      }
      if (hasSteelBox !== undefined && hasSteelBox !== '') {
        whereClauses.push('m.HasSteelBox = :hasSteelBox');
        replacements.hasSteelBox = parseInt(hasSteelBox);
      }
      if (nocs) {
        whereClauses.push('c.NOCS LIKE :nocs');
        replacements.nocs = `%${nocs}%`;
      }
      if (dateFrom) {
        whereClauses.push("m.InstallDate >= :dateFrom");
        replacements.dateFrom = dateFrom;
      }
      if (dateTo) {
        whereClauses.push("m.InstallDate <= :dateTo");
        replacements.dateTo = dateTo + ' 23:59:59';
      }
      if (installedBy) {
        whereClauses.push('a.UserName LIKE :installedBy');
        replacements.installedBy = `%${installedBy}%`;
      }
      if (search) {
        whereClauses.push(`(
          m.OldConsumerId LIKE :search OR
          m.CustomerId    LIKE :search OR
          m.NewMeterNoOCR LIKE :search OR
          m.OldMeterNoOCR LIKE :search OR
          c.CUSTOMER_NAME LIKE :search
        )`);
        replacements.search = `%${search}%`;
      }

      const whereSQL = whereClauses.join(' AND ');

      replacements.offset = offset;
      replacements.limit = parseInt(limit);

      // Single query: COUNT(*) OVER() avoids a separate round-trip for pagination total.
      // WITH (NOLOCK) prevents reads from blocking behind active inserts/updates.
      const dataQuery = `
        SELECT
          m.Id, m.CustomerId, m.OldConsumerId, m.InstallDate,
          m.Latitude, m.Longitude,
          m.HasOldMeterNo, m.OldMeterNoOCR, m.OldMeterNoImgUrl,
          m.HasOldMeterReading, m.OldMeterReadingOCR,
          m.OldMeterPeak, m.OldMeterOffPeak, m.OldMeterKVAR,
          m.HasNewMeterNo, m.NewMeterNoOCR, m.NewMeterNoImgUrl,
          m.NewMeterType,
          m.HasBatteryCoverSeal, m.BatteryCoverSealOCR, m.BatteryCoverSealImgUrl,
          m.HasTerminalCoverSeal1, m.TerminalCoverSealOCR1, m.TerminalCoverSealImgUrl1,
          m.HasTerminalCoverSeal2, m.TerminalCoverSealOCR2, m.TerminalCoverSealImgUrl2,
          m.HasSteelBox, m.MeterInstalledBy,
          m.IsApproved, m.IsMDMEntry, m.IsAppsEntry,
          m.HasRevisit, m.RectifyStatus,
          m.CreateBy, m.CreateDate, m.UpdateDate,
          m.LocalId,
          c.CUSTOMER_NAME AS CustomerName,
          c.ADDRESS       AS CustomerAddress,
          c.MOBILE_NO     AS CustomerMobile,
          c.NOCS          AS CustomerNOCS,
          c.FEEDER_NAME   AS CustomerFeeder,
          c.ZONE          AS CustomerZone,
          a.UserName      AS InstallerName,
          COUNT(*) OVER()  AS TotalCount
        FROM [${DB_NAME}].[dbo].[MeterInfo_test] m WITH (NOLOCK)
        LEFT JOIN [${DB_NAME}].[dbo].[Customer] c WITH (NOLOCK)
          ON LTRIM(RTRIM(CAST(m.OldConsumerId AS VARCHAR(50)))) = CAST(c.OLD_CONSUMER_ID AS VARCHAR(50))
        LEFT JOIN [${DB_NAME}].[dbo].[AdminSecurity] a WITH (NOLOCK)
          ON m.CreateBy = a.SecurityId
        WHERE ${whereSQL}
        ORDER BY m.${actualSortBy} ${actualSortOrder}
        OFFSET :offset ROWS FETCH NEXT :limit ROWS ONLY
      `;

      const rawRows = await sequelize.query(dataQuery, {
        replacements,
        type: sequelize.QueryTypes.SELECT
      });

      const total = rawRows.length > 0 ? (rawRows[0].TotalCount || 0) : 0;
      // Strip the internal pagination helper column before returning to the client
      const rows = rawRows.map(({ TotalCount, ...r }) => r);

      return paginatedResponse(res, rows, {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(total / parseInt(limit))
      }, 'CMO records retrieved successfully');

    } catch (error) {
      logger.error(`CMS Dashboard getAll error: ${error.message}`);
      return errorResponse(res, error.message, 500);
    }
  }

  /**
   * PATCH /api/cmo/cms-list/:id/approval
   * Toggle IsApproved for a single MeterInfo_test record.
   * Body: { isApproved: 0 | 1 }
   * isApproved = 1 → Approved
   * isApproved = 0 → Pending (returned to field worker for re-edit)
   */
  async updateApproval(req, res) {
    try {
      const { id } = req.params;
      const { isApproved } = req.body;

      if (isApproved === undefined || isApproved === null) {
        return errorResponse(res, 'isApproved is required (0 or 1)', 400);
      }

      const approvedValue = parseInt(isApproved) === 1 ? 1 : 0;
      const DB_NAME = process.env.DB_NAME || 'MeterOCRDPDC';

      await sequelize.query(`
        UPDATE [${DB_NAME}].[dbo].[MeterInfo_test]
        SET IsApproved = :isApproved,
            UpdateDate = GETDATE()
        WHERE Id = :id AND IsActive = 1
      `, {
        replacements: { isApproved: approvedValue, id: parseInt(id) },
        type: sequelize.QueryTypes.UPDATE
      });

      const message = approvedValue === 1
        ? 'Record approved successfully'
        : 'Record unapproved — returned to pending for re-edit';

      logger.info(`Approval updated: MeterInfo Id=${id} → IsApproved=${approvedValue}`);
      return successResponse(res, { id: parseInt(id), isApproved: approvedValue }, message);

    } catch (error) {
      logger.error(`updateApproval error: ${error.message}`);
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
        LEFT JOIN [${DB_NAME}].[dbo].[Customer] c ON LTRIM(RTRIM(m.CustomerId)) = CAST(c.OLD_CONSUMER_ID AS VARCHAR(50))
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
   * POST /api/cmo/upload-customers
   * Insert customer records from Excel upload into Customer table
   * Expects { customers: [...] } with Excel-parsed data
   * Skips duplicates based on OLD_CONSUMER_ID
   */
  async uploadCustomers(req, res) {
    try {
      const { customers } = req.body;

      if (!customers || !Array.isArray(customers) || customers.length === 0) {
        return errorResponse(res, 'customers array is required and must not be empty', 400);
      }

      const DB_NAME = process.env.DB_NAME || 'MeterOCRDPDC';

      // Get existing OLD_CONSUMER_IDs to skip duplicates
      const existingIds = new Set();
      const allConsumerIds = customers
        .map(c => c.OLD_CONSUMER_ID)
        .filter(id => id != null && String(id).trim() !== '')
        .map(id => String(id).trim());

      const uniqueConsumerIds = [...new Set(allConsumerIds)];

      // Use 500 for SELECT (only 1 param/row, well within SQL Server's 2100 param limit)
      const selectChunkSize = 500;
      for (let i = 0; i < uniqueConsumerIds.length; i += selectChunkSize) {
        const chunk = uniqueConsumerIds.slice(i, i + selectChunkSize);
        const placeholders = chunk.map((_, idx) => `:id${idx}`).join(',');
        const replacements = {};
        chunk.forEach((id, idx) => { replacements[`id${idx}`] = id; });

        const results = await sequelize.query(`
          SELECT CAST([OLD_CONSUMER_ID] AS VARCHAR(50)) AS OLD_CONSUMER_ID
          FROM [${DB_NAME}].[dbo].[Customer]
          WHERE CAST([OLD_CONSUMER_ID] AS VARCHAR(50)) IN (${placeholders})
        `, { replacements, type: sequelize.QueryTypes.SELECT });

        results.forEach(r => existingIds.add(String(r.OLD_CONSUMER_ID).trim()));
      }

      let inserted = 0;
      let skipped = 0;
      const errors = [];

      // Filter out duplicates
      const toInsert = customers.filter(c => {
        const consumerId = c.OLD_CONSUMER_ID != null ? String(c.OLD_CONSUMER_ID).trim() : '';
        if (!consumerId || existingIds.has(consumerId)) {
          skipped++;
          return false;
        }
        return true;
      });

      // INSERT chunk size: 9 params/row × 200 rows = 1800 params — safely under SQL Server's 2100 limit
      const insertChunkSize = 200;
      for (let i = 0; i < toInsert.length; i += insertChunkSize) {
        const chunk = toInsert.slice(i, i + insertChunkSize);

        try {
          const values = [];
          const replacements = {};

          chunk.forEach((row, idx) => {
            values.push(`(:indexNo${idx}, :oldConsumerId${idx}, :customerName${idx}, :address${idx}, :custTariffCategory${idx}, :sanctionedLoad${idx}, :cpcCpr${idx}, :nocs${idx}, :nocsCode${idx}, 1, GETDATE())`);
            replacements[`indexNo${idx}`] = row.INDEX_NO || null;
            replacements[`oldConsumerId${idx}`] = row.OLD_CONSUMER_ID != null ? String(row.OLD_CONSUMER_ID).trim() : null;
            replacements[`customerName${idx}`] = row.CUSTOMER_NAME || null;
            replacements[`address${idx}`] = row.ADDRESS || null;
            replacements[`custTariffCategory${idx}`] = row.CUST_TARIFF_CATEGORY || null;
            replacements[`sanctionedLoad${idx}`] = row.SANCTIONED_LOAD != null ? String(row.SANCTIONED_LOAD) : null;
            replacements[`cpcCpr${idx}`] = row.CPC_CPR || null;
            replacements[`nocs${idx}`] = row.NOCS || null;
            replacements[`nocsCode${idx}`] = row.NOCS_CODE || null;
          });

          const query = `
            INSERT INTO [${DB_NAME}].[dbo].[Customer]
              ([INDEX_NO], [OLD_CONSUMER_ID], [CUSTOMER_NAME], [ADDRESS], [CUST_TARIFF_CATEGORY], [SANCTIONED_LOAD], [CPC_CPR], [NOCS], [NOCS_CODE], [IsActive], [CreateDate])
            VALUES ${values.join(', ')}
          `;

          await sequelize.query(query, { replacements, type: sequelize.QueryTypes.INSERT });
          inserted += chunk.length;
        } catch (chunkError) {
          logger.error(`Upload customers chunk error (rows ${i + 1}-${i + chunk.length}): ${chunkError.message}`);
          errors.push(`Rows ${i + 1}-${i + chunk.length}: ${chunkError.message}`);
        }
      }

      logger.info(`Upload customers: inserted ${inserted}, skipped ${skipped}, errors ${errors.length}`);

      return successResponse(res, {
        inserted,
        skipped,
        errors
      }, `Customer upload completed. ${inserted} inserted, ${skipped} skipped.`);

    } catch (error) {
      logger.error(`Upload customers error: ${error.message}`);
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
