const { NOCS, DCU, MeterInfo } = require('../models');
const { successResponse, errorResponse } = require('../utils/response');
const logger = require('../utils/logger');
const { Op } = require('sequelize');

class MapController {
  // Get all NOCS (substations)
  async getAllNOCS(req, res) {
    try {
      const nocsList = await NOCS.findAll({
        order: [['NOCS_NAME', 'ASC']]
      });

      const data = nocsList.map(nocs => nocs.toJSON());
      return successResponse(res, data, 'NOCS retrieved successfully');
    } catch (error) {
      logger.error(`Get NOCS error: ${error.message}`);
      return errorResponse(res, error.message, 500);
    }
  }

  // Get all DCUs
  async getAllDCUs(req, res) {
    try {
      const { nocs } = req.query; // Optional filter by NOCS

      let whereClause = {};
      if (nocs) {
        whereClause.NOCS = nocs;
      }

      const dcuList = await DCU.findAll({
        where: whereClause,
        order: [['DCU_ID', 'ASC']]
      });

      const data = dcuList.map(dcu => dcu.toJSON());
      return successResponse(res, data, 'DCUs retrieved successfully');
    } catch (error) {
      logger.error(`Get DCUs error: ${error.message}`);
      return errorResponse(res, error.message, 500);
    }
  }

  // Get all map data (NOCS + DCUs)
  async getAllMapData(req, res) {
    try {
      const { nocs } = req.query; // Optional filter by NOCS

      // Get NOCS
      let nocsWhereClause = {};
      if (nocs) {
        nocsWhereClause.NOCS_NAME = nocs;
      }

      const nocsList = await NOCS.findAll({
        where: nocsWhereClause,
        order: [['NOCS_NAME', 'ASC']]
      });

      // Get DCUs
      let dcuWhereClause = {};
      if (nocs) {
        dcuWhereClause.NOCS = nocs;
      }

      const dcuList = await DCU.findAll({
        where: dcuWhereClause,
        order: [['DCU_ID', 'ASC']]
      });

      const data = {
        nocs: nocsList.map(n => n.toJSON()),
        dcus: dcuList.map(d => d.toJSON()),
        nocsCount: nocsList.length,
        dcuCount: dcuList.length
      };

      return successResponse(res, data, 'Map data retrieved successfully');
    } catch (error) {
      logger.error(`Get map data error: ${error.message}`);
      return errorResponse(res, error.message, 500);
    }
  }

  // Get NOCS by ID
  async getNOCSById(req, res) {
    try {
      const { id } = req.params;
      const nocs = await NOCS.findByPk(id);

      if (!nocs) {
        return errorResponse(res, 'NOCS not found', 404);
      }

      // Get DCUs under this NOCS
      const dcus = await DCU.findAll({
        where: { NOCS: nocs.NOCS_NAME },
        order: [['DCU_ID', 'ASC']]
      });

      const data = {
        ...nocs.toJSON(),
        dcus: dcus.map(d => d.toJSON()),
        dcuCount: dcus.length
      };

      return successResponse(res, data, 'NOCS retrieved successfully');
    } catch (error) {
      logger.error(`Get NOCS by ID error: ${error.message}`);
      return errorResponse(res, error.message, 500);
    }
  }

  // Get DCU by ID
  async getDCUById(req, res) {
    try {
      const { id } = req.params;
      const dcu = await DCU.findByPk(id);

      if (!dcu) {
        return errorResponse(res, 'DCU not found', 404);
      }

      return successResponse(res, dcu.toJSON(), 'DCU retrieved successfully');
    } catch (error) {
      logger.error(`Get DCU by ID error: ${error.message}`);
      return errorResponse(res, error.message, 500);
    }
  }

  // Get CMOs with coordinates from MeterInfo — viewport-based (bbox) for performance.
  // With 350,000+ records, loading all at once is not feasible.
  // Client must send bounding box (latMin/latMax/lngMin/lngMax) so only the
  // visible map area is queried. A hard limit caps results per request.
  async getCMOsWithCoordinates(req, res) {
    try {
      const {
        search, status,
        latMin, latMax, lngMin, lngMax,   // bounding box (viewport)
        limit = 500,                       // max records to return (default 500)
        dateFrom, dateTo,                  // install date range (YYYY-MM-DD)
      } = req.query;

      // Hard cap: never return more than 1000 records in one call
      const actualLimit = Math.min(Math.max(parseInt(limit) || 500, 1), 1000);

      // Base filter — valid coordinates + active records
      let whereClause = {
        Latitude:  { [Op.ne]: null },
        Longitude: { [Op.ne]: null },
        IsActive:  1,
      };

      // Bounding box filter — only load what is visible on the map
      if (latMin != null && latMax != null && lngMin != null && lngMax != null) {
        const south = parseFloat(latMin);
        const north = parseFloat(latMax);
        const west  = parseFloat(lngMin);
        const east  = parseFloat(lngMax);

        if (!isNaN(south) && !isNaN(north) && !isNaN(west) && !isNaN(east)) {
          whereClause.Latitude  = { [Op.between]: [south, north] };
          whereClause.Longitude = { [Op.between]: [west,  east]  };
        }
      }

      // Search filter — OldConsumerId is the readable 8-digit consumer ID
      if (search) {
        whereClause[Op.or] = [
          { OldConsumerId: { [Op.like]: `%${search}%` } },
          { OldMeterNoOCR: { [Op.like]: `%${search}%` } },
          { OldMeterNoOld: { [Op.like]: `%${search}%` } },
          { NewMeterNoOCR: { [Op.like]: `%${search}%` } },
          { NewMeterNoOld: { [Op.like]: `%${search}%` } },
        ];
      }

      // Status filter
      if (status) {
        if (status === 'approved') {
          whereClause.IsApproved = 1;
        } else if (status === 'pending') {
          whereClause.IsApproved = 0;
          whereClause.HasRevisit = 0;
        } else if (status === 'revisit') {
          whereClause.HasRevisit = 1;
        }
      }

      // Install date range filter
      if (dateFrom || dateTo) {
        const dateFilter = {};
        if (dateFrom) dateFilter[Op.gte] = new Date(dateFrom + 'T00:00:00');
        if (dateTo)   dateFilter[Op.lte] = new Date(dateTo   + 'T23:59:59');
        whereClause.InstallDate = dateFilter;
      }

      const meterInfoList = await MeterInfo.findAll({
        where: whereClause,
        order: [['Id', 'DESC']],
        limit: actualLimit,
        // Lightweight attributes — only what the map pin + info card needs
        attributes: [
          'Id', 'CustomerId', 'OldConsumerId', 'InstallDate',
          'Latitude', 'Longitude',
          'OldMeterNoOCR', 'OldMeterNoOld',
          'NewMeterNoOCR', 'NewMeterNoOld', 'NewMeterType', 'NewMeterBillingType',
          'HasSteelBox', 'MeterInstalledBy',
          'IsApproved', 'HasRevisit', 'RectifyStatus', 'RectifyMessage',
          'CreateDate',
        ],
      });

      const hasMore = meterInfoList.length === actualLimit;

      // Transform data for Flutter app
      const data = meterInfoList.map(meter => {
        const m = meter.get({ plain: true });

        // Determine status
        let status = 'pending';
        if (m.IsApproved === 1) {
          status = 'approved';
        } else if (m.HasRevisit === 1) {
          status = 'revisit';
        }

        return {
          id: m.Id,
          customerId: m.CustomerId,
          oldConsumerId: m.OldConsumerId,
          installDate: m.InstallDate,
          latitude: m.Latitude ? parseFloat(m.Latitude) : null,
          longitude: m.Longitude ? parseFloat(m.Longitude) : null,
          oldMeterNumber: m.OldMeterNoOCR || m.OldMeterNoOld,
          newMeterNumber: m.NewMeterNoOCR || m.NewMeterNoOld,
          newMeterType: m.NewMeterType,
          newMeterBillingType: m.NewMeterBillingType,
          hasSteelBox: m.HasSteelBox === 1,
          installedBy: m.MeterInstalledBy,
          status: status,
          isApproved: m.IsApproved === 1,
          hasRevisit: m.HasRevisit === 1,
          rectifyStatus: m.RectifyStatus,
          rectifyMessage: m.RectifyMessage,
          createdAt: m.CreateDate,
        };
      });

      return successResponse(res, {
        cmos: data,
        count: data.length,
        hasMore,       // true if more records exist beyond the limit in this viewport
        limit: actualLimit,
      }, `${data.length} CMOs loaded${hasMore ? ` (showing first ${actualLimit}, zoom in for more)` : ''}`);
    } catch (error) {
      logger.error(`Get CMOs with coordinates error: ${error.message}`);
      return errorResponse(res, error.message, 500);
    }
  }

  // Get CMO by ID from MeterInfo table
  async getCMOById(req, res) {
    try {
      const { id } = req.params;
      const meter = await MeterInfo.findByPk(id);

      if (!meter) {
        return errorResponse(res, 'CMO not found', 404);
      }

      const m = meter.get({ plain: true });

      // Determine status
      let status = 'pending';
      if (m.IsApproved === 1) {
        status = 'approved';
      } else if (m.HasRevisit === 1) {
        status = 'revisit';
      }

      const data = {
        id: m.Id,
        customerId: m.CustomerId,
        oldConsumerId: m.OldConsumerId,
        installDate: m.InstallDate,
        latitude: m.Latitude ? parseFloat(m.Latitude) : null,
        longitude: m.Longitude ? parseFloat(m.Longitude) : null,
        oldMeterNumber: m.OldMeterNoOCR || m.OldMeterNoOld,
        oldMeterNoImgUrl: m.OldMeterNoImgUrl,
        oldMeterReading: m.OldMeterReadingOCR || m.OldMeterReadingOld,
        oldMeterReadingImgUrl: m.OldMeterReadingImgUrl,
        oldMeterPeak: m.OldMeterPeak,
        oldMeterOffPeak: m.OldMeterOffPeak,
        oldMeterKVAR: m.OldMeterKVAR,
        newMeterNumber: m.NewMeterNoOCR || m.NewMeterNoOld,
        newMeterNoImgUrl: m.NewMeterNoImgUrl,
        newMeterType: m.NewMeterType,
        newMeterBillingType: m.NewMeterBillingType,
        newMeterConnectionType: m.NewMeterConnectionType,
        batteryCoverSeal: m.BatteryCoverSealOCR || m.BatteryCoverSealOld,
        batteryCoverSealImgUrl: m.BatteryCoverSealImgUrl,
        terminalSeal1: m.TerminalCoverSealOCR1 || m.TerminalCoverSealOld1,
        terminalSealImgUrl1: m.TerminalCoverSealImgUrl1,
        terminalSeal2: m.TerminalCoverSealOCR2 || m.TerminalCoverSealOld2,
        terminalSealImgUrl2: m.TerminalCoverSealImgUrl2,
        hasSteelBox: m.HasSteelBox === 1,
        isSteelBoxRemove: m.IsSteelBoxRemove === 1,
        steelBoxRemoveUrl: m.SteelBoxRemoveUrl,
        installedBy: m.MeterInstalledBy,
        status: status,
        isApproved: m.IsApproved === 1,
        approvedBy: m.ApprovedBy,
        approvedDate: m.ApprovedDate,
        hasRevisit: m.HasRevisit === 1,
        revisitDate: m.RevisitDt,
        rectifyStatus: m.RectifyStatus,
        rectifyMessage: m.RectifyMessage,
        createdAt: m.CreateDate,
        updatedAt: m.UpdateDate
      };

      return successResponse(res, data, 'CMO retrieved successfully');
    } catch (error) {
      logger.error(`Get CMO by ID error: ${error.message}`);
      return errorResponse(res, error.message, 500);
    }
  }
}

module.exports = new MapController();
