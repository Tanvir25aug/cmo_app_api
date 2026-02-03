const { MeterInfo, AdminSecurity } = require('../models');
const { sequelize } = require('../config/database');
const { Op } = require('sequelize');

// Helper function to format date for SQL Server
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
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  const seconds = String(date.getSeconds()).padStart(2, '0');
  const ms = String(date.getMilliseconds()).padStart(3, '0');

  return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}.${ms}`;
}

class BulkCmoService {
  /**
   * Bulk sync multiple CMOs in a single transaction
   * @param {number} userId - User ID
   * @param {number} securityId - Security ID for CreateBy field
   * @param {object} bulkData - Bulk CMO data with building info and CMOs array
   */
  async bulkSyncCMOs(userId, securityId, bulkData) {
    const { buildingName, buildingAddress, latitude, longitude, feeder, installBy, CMOs } = bulkData;

    const results = {
      bulkGroupId: bulkData.bulkGroupId || `bulk-${Date.now()}`,
      buildingName,
      totalCount: CMOs ? CMOs.length : 0,
      successCount: 0,
      failedCount: 0,
      success: [],
      failed: []
    };

    if (!CMOs || CMOs.length === 0) {
      return results;
    }

    // Use transaction for atomic bulk insert
    const transaction = await sequelize.transaction();

    try {
      for (const cmoData of CMOs) {
        try {
          // Check if record already exists by CustomerId/OldConsumerId
          const existingRecord = await MeterInfo.findOne({
            where: {
              [Op.or]: [
                { CustomerId: cmoData.CustomerId },
                { OldConsumerId: cmoData.OldConsumerId || cmoData.CustomerId }
              ]
            },
            transaction
          });

          let meterInfo;

          // Use shared building data if not provided in individual CMO
          const finalLatitude = cmoData.Latitude || latitude;
          const finalLongitude = cmoData.Longitude || longitude;
          const finalInstallBy = cmoData.MeterInstalledBy || installBy;

          if (existingRecord) {
            // Update existing record
            const updateData = {
              ...cmoData,
              Latitude: finalLatitude,
              Longitude: finalLongitude,
              MeterInstalledBy: finalInstallBy,
              UpdateBy: securityId,
              UpdateDate: formatDateForSqlServer(null)
            };

            if (updateData.InstallDate) {
              updateData.InstallDate = formatDateForSqlServer(updateData.InstallDate);
            }
            if (updateData.RevisitDt) {
              updateData.RevisitDt = formatDateForSqlServer(updateData.RevisitDt);
            }
            if (updateData.ApprovedDate) {
              updateData.ApprovedDate = formatDateForSqlServer(updateData.ApprovedDate);
            }

            await existingRecord.update(updateData, { transaction });
            meterInfo = existingRecord;
          } else {
            // Create new record
            meterInfo = await MeterInfo.create({
              CustomerId: cmoData.CustomerId,
              OldConsumerId: cmoData.OldConsumerId || cmoData.CustomerId,
              InstallDate: formatDateForSqlServer(cmoData.InstallDate),
              Latitude: finalLatitude,
              Longitude: finalLongitude,
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
              MeterInstalledBy: finalInstallBy,
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
            }, { transaction });
          }

          results.successCount++;
          results.success.push({
            localId: cmoData.LocalId,
            serverId: meterInfo.Id,
            customerId: cmoData.CustomerId,
            meterIndex: cmoData.MeterIndex,
            status: existingRecord ? 'updated' : 'created'
          });

        } catch (error) {
          console.error('Bulk sync error for customer', cmoData.CustomerId, ':', error.message);
          results.failedCount++;
          results.failed.push({
            localId: cmoData.LocalId,
            customerId: cmoData.CustomerId,
            meterIndex: cmoData.MeterIndex,
            error: error.message
          });
        }
      }

      // Commit transaction if at least some succeeded
      if (results.successCount > 0) {
        await transaction.commit();
      } else {
        await transaction.rollback();
      }

      return results;

    } catch (error) {
      // Rollback on any error
      await transaction.rollback();
      console.error('Bulk sync transaction error:', error);
      throw error;
    }
  }

  /**
   * Get bulk sync statistics
   */
  async getBulkSyncStats() {
    try {
      const total = await MeterInfo.count({ where: { IsActive: 1 } });
      const today = new Date();
      const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());

      const todayCount = await MeterInfo.count({
        where: {
          IsActive: 1,
          CreateDate: {
            [Op.gte]: formatDateForSqlServer(todayStart).split(' ')[0]
          }
        }
      });

      return {
        totalRecords: total,
        todayRecords: todayCount
      };
    } catch (error) {
      console.error('Bulk stats error:', error);
      return { totalRecords: 0, todayRecords: 0 };
    }
  }
}

module.exports = new BulkCmoService();
