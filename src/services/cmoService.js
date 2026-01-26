const { CMO, AdminSecurity } = require('../models');
const { Op } = require('sequelize');

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

  // Bulk sync CMOs from mobile app
  async syncCMOs(userId, cmos) {
    const results = {
      success: [],
      failed: []
    };

    for (const cmoData of cmos) {
      try {
        let cmo;

        // Check if CMO already exists (by client-side ID)
        if (cmoData.id) {
          cmo = await CMO.findOne({ where: { id: cmoData.id, userId } });
        }

        if (cmo) {
          // Update existing
          await cmo.update({
            ...cmoData,
            isSynced: true,
            syncedAt: new Date()
          });
        } else {
          // Create new
          cmo = await CMO.create({
            ...cmoData,
            userId,
            isSynced: true,
            syncedAt: new Date()
          });
        }

        results.success.push({
          clientId: cmoData.id,
          serverId: cmo.id,
          status: 'synced'
        });
      } catch (error) {
        results.failed.push({
          clientId: cmoData.id,
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
