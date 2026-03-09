const { CMO, AdminSecurity, MeterInfo } = require('../models');
const { Op } = require('sequelize');

// Helper function to format date for SQL Server (without timezone offset)
function formatDateForSqlServer(dateString) {
  let date;
  if (!dateString) {
    date = new Date();
  } else {
    date = new Date(dateString);
    if (isNaN(date.getTime())) {
      date = new Date();
    }
  }
  // Format as YYYY-MM-DD HH:mm:ss.SSS (SQL Server compatible)
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  const seconds = String(date.getSeconds()).padStart(2, '0');
  const ms = String(date.getMilliseconds()).padStart(3, '0');

  return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}.${ms}`;
}

class CMOService {
  // Get all CMOs with pagination and filters
  async getAllCMOs(userId, options = {}) {
    const {
      page = 1,
      limit = 20,
      status,
      search,
      sortBy = 'createdAt',
      sortOrder = 'DESC'
    } = options;

    const offset = (page - 1) * limit;

    // Build where clause
    const where = { userId };

    if (status) {
      where.status = status;
    }

    if (search) {
      where[Op.or] = [
        { customerName: { [Op.like]: `%${search}%` } },
        { mobileNumber: { [Op.like]: `%${search}%` } },
        { customerId: { [Op.like]: `%${search}%` } },
        { newMeterId: { [Op.like]: `%${search}%` } }
      ];
    }

    // Get CMOs
    const { count, rows } = await CMO.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset,
      order: [[sortBy, sortOrder]],
      include: [{
        model: AdminSecurity,
        as: 'user',
        attributes: ['SecurityId', 'UserId', 'UserName']
      }]
    });

    return {
      cmos: rows,
      pagination: {
        total: count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(count / limit)
      }
    };
  }

  // Get single CMO
  async getCMOById(id, userId) {
    const cmo = await CMO.findOne({
      where: { id, userId },
      include: [{
        model: AdminSecurity,
        as: 'user',
        attributes: ['SecurityId', 'UserId', 'UserName']
      }]
    });

    if (!cmo) {
      throw new Error('CMO request not found');
    }

    return cmo;
  }

  // Create new CMO
  async createCMO(userId, cmoData) {
    const cmo = await CMO.create({
      ...cmoData,
      userId,
      status: cmoData.status || 'draft',
      isSynced: false
    });

    return cmo;
  }

  // Update CMO
  async updateCMO(id, userId, updates) {
    const cmo = await CMO.findOne({ where: { id, userId } });

    if (!cmo) {
      throw new Error('CMO request not found');
    }

    // Don't allow updating these fields
    delete updates.id;
    delete updates.userId;

    await cmo.update(updates);

    return cmo;
  }

  // Delete CMO
  async deleteCMO(id, userId) {
    const cmo = await CMO.findOne({ where: { id, userId } });

    if (!cmo) {
      throw new Error('CMO request not found');
    }

    await cmo.destroy();

    return { message: 'CMO request deleted successfully' };
  }

  // Bulk sync CMOs from mobile app to MeterInfo_test table
  async syncCMOs(userId, cmos, securityId) {
    const results = {
      success: [],
      failed: []
    };

    for (const cmoData of cmos) {
      try {
        // Check if record already exists by CustomerId/OldConsumerId
        const existingRecord = await MeterInfo.findOne({
          where: {
            [Op.or]: [
              { CustomerId: cmoData.CustomerId },
              { OldConsumerId: cmoData.OldConsumerId || cmoData.CustomerId }
            ]
          }
        });

        let meterInfo;

        if (existingRecord) {
          // Update existing record - format dates properly
          const updateData = { ...cmoData };
          if (updateData.InstallDate) {
            updateData.InstallDate = formatDateForSqlServer(updateData.InstallDate);
          }
          if (updateData.RevisitDt) {
            updateData.RevisitDt = formatDateForSqlServer(updateData.RevisitDt);
          }
          if (updateData.ApprovedDate) {
            updateData.ApprovedDate = formatDateForSqlServer(updateData.ApprovedDate);
          }
          updateData.UpdateBy = securityId;
          updateData.UpdateDate = formatDateForSqlServer(null);
          await existingRecord.update(updateData);
          meterInfo = existingRecord;
        } else {
          // Create new record in MeterInfo_test table
          meterInfo = await MeterInfo.create({
            CustomerId: cmoData.CustomerId,
            OldConsumerId: cmoData.OldConsumerId || cmoData.CustomerId,
            InstallDate: formatDateForSqlServer(cmoData.InstallDate),
            Latitude: cmoData.Latitude,
            Longitude: cmoData.Longitude,
            HasOldMeterNo: cmoData.HasOldMeterNo || 0,
            OldMeterNoImgUrl: cmoData.OldMeterNoImgUrl,
            OldMeterNoOCR: cmoData.OldMeterNoOCR,
            OldMeterNoOld: cmoData.OldMeterNoOld,
            HasOldMeterReading: cmoData.HasOldMeterReading || 0,
            OldMeterReadingImgUrl: cmoData.OldMeterReadingImgUrl,
            OldMeterReadingOCR: cmoData.OldMeterReadingOCR,
            OldMeterReadingOld: cmoData.OldMeterReadingOld,
            OldMeterPeak: cmoData.OldMeterPeak,
            OldMeterOffPeak: cmoData.OldMeterOffPeak,
            OldMeterKVAR: cmoData.OldMeterKVAR,
            HasNewMeterNo: cmoData.HasNewMeterNo || 0,
            NewMeterNoImgUrl: cmoData.NewMeterNoImgUrl,
            NewMeterNoOCR: cmoData.NewMeterNoOCR,
            NewMeterNoOld: cmoData.NewMeterNoOld,
            IsNewMeterDuplicate: cmoData.IsNewMeterDuplicate || 0,
            NewMeterType: cmoData.NewMeterType,
            NewMeterBillingType: cmoData.NewMeterBillingType,
            NewMeterConnectionType: cmoData.NewMeterConnectionType,
            IsPVCWireInstall: cmoData.IsPVCWireInstall || 0,
            PVCWireSpec: cmoData.PVCWireSpec,
            PVCWireLength: cmoData.PVCWireLength,
            HasBatteryCoverSeal: cmoData.HasBatteryCoverSeal || 0,
            BatteryCoverSealImgUrl: cmoData.BatteryCoverSealImgUrl,
            BatteryCoverSealOCR: cmoData.BatteryCoverSealOCR,
            BatteryCoverSealOld: cmoData.BatteryCoverSealOld,
            HasTerminalCoverSeal1: cmoData.HasTerminalCoverSeal1 || 0,
            TerminalCoverSealImgUrl1: cmoData.TerminalCoverSealImgUrl1,
            TerminalCoverSealOCR1: cmoData.TerminalCoverSealOCR1,
            TerminalCoverSealOld1: cmoData.TerminalCoverSealOld1,
            HasTerminalCoverSeal2: cmoData.HasTerminalCoverSeal2 || 0,
            TerminalCoverSealImgUrl2: cmoData.TerminalCoverSealImgUrl2,
            TerminalCoverSealOCR2: cmoData.TerminalCoverSealOCR2,
            TerminalCoverSealOld2: cmoData.TerminalCoverSealOld2,
            HasSteelBox: cmoData.HasSteelBox || 0,
            IsSteelBoxRemove: cmoData.IsSteelBoxRemove || 0,
            SteelBoxRemoveUrl: cmoData.SteelBoxRemoveUrl,
            MeterInstalledBy: cmoData.MeterInstalledBy,
            HasRevisit: cmoData.HasRevisit || 0,
            RevisitDt: cmoData.RevisitDt ? formatDateForSqlServer(cmoData.RevisitDt) : null,
            RectifyStatus: cmoData.RectifyStatus,
            RectifyMessage: cmoData.RectifyMessage,
            IsApproved: cmoData.IsApproved || 0,
            ApprovedBy: cmoData.ApprovedBy,
            ApprovedDate: cmoData.ApprovedDate ? formatDateForSqlServer(cmoData.ApprovedDate) : null,
            IsMDMEntry: cmoData.IsMDMEntry || 0,
            IsAppsEntry: 1,
            IsActive: 1,
            CreateBy: securityId,
            CreateDate: formatDateForSqlServer(null),
            UpdateBy: null,
            UpdateDate: null
          });
        }

        results.success.push({
          clientId: cmoData.LocalId,
          serverId: meterInfo.Id,
          customerId: cmoData.CustomerId,
          status: existingRecord ? 'updated' : 'created'
        });
      } catch (error) {
        // Log error without full stack trace to reduce log size
        console.error(`Sync error for customer ${cmoData.CustomerId}: ${error.message}`);
        results.failed.push({
          clientId: cmoData.LocalId,
          customerId: cmoData.CustomerId,
          newMeterId: cmoData.NewMeterNoOCR,
          error: error.message
        });
      }
    }

    return results;
  }

  // Get unsynced CMOs (for download to mobile)
  async getUnsyncedCMOs(userId, lastSyncDate) {
    const where = {
      userId,
      updatedAt: {
        [Op.gt]: lastSyncDate || new Date(0)
      }
    };

    const cmos = await CMO.findAll({ where });

    return cmos;
  }

  // Get statistics
  async getStatistics(userId) {
    const total = await CMO.count({ where: { userId } });
    const draft = await CMO.count({ where: { userId, status: 'draft' } });
    const pending = await CMO.count({ where: { userId, status: 'pending' } });
    const uploaded = await CMO.count({ where: { userId, status: 'uploaded' } });
    const approved = await CMO.count({ where: { userId, status: 'approved' } });

    return {
      total,
      draft,
      pending,
      uploaded,
      approved
    };
  }
}

module.exports = new CMOService();
