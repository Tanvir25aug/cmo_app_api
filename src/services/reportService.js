const { MeterInfo, AdminSecurity } = require('../models');
const { sequelize } = require('../config/database');
const { Op, fn, col, literal } = require('sequelize');

class ReportService {
  /**
   * Get complete dashboard data from SQL Server
   * Returns all statistics in one call for efficiency
   */
  async getDashboardData() {
    try {
      const [cmoStats, userCount, customerCount, topUsers, weeklyData] = await Promise.all([
        this.getCMOStatistics(),
        this.getUserCount(),
        this.getCustomerCount(),
        this.getTopUsersByCMOCount(5),
        this.getWeeklyData()
      ]);

      return {
        cmoStats,
        userCount,
        customerCount,
        topUsers,
        weeklyData
      };
    } catch (error) {
      console.error('Dashboard data error:', error);
      throw error;
    }
  }

  /**
   * Get CMO statistics from MeterInfo_test table
   */
  async getCMOStatistics() {
    try {
      // Total count
      const total = await MeterInfo.count({
        where: { IsActive: 1 }
      });

      // Approved count (synced)
      const synced = await MeterInfo.count({
        where: { IsActive: 1, IsApproved: 1 }
      });

      // Pending (not approved yet)
      const pending = await MeterInfo.count({
        where: { IsActive: 1, IsApproved: 0 }
      });

      // With GPS location
      const withLocation = await MeterInfo.count({
        where: {
          IsActive: 1,
          Latitude: { [Op.ne]: null },
          Longitude: { [Op.ne]: null }
        }
      });

      // Today's count
      const today = new Date();
      const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());
      const todayEnd = new Date(todayStart);
      todayEnd.setDate(todayEnd.getDate() + 1);

      const todayCount = await MeterInfo.count({
        where: {
          IsActive: 1,
          CreateDate: {
            [Op.gte]: this.formatDate(todayStart),
            [Op.lt]: this.formatDate(todayEnd)
          }
        }
      });

      // This week's count
      const weekStart = new Date(today);
      weekStart.setDate(today.getDate() - today.getDay());
      weekStart.setHours(0, 0, 0, 0);

      const thisWeekCount = await MeterInfo.count({
        where: {
          IsActive: 1,
          CreateDate: {
            [Op.gte]: this.formatDate(weekStart)
          }
        }
      });

      // This month's count
      const monthStart = new Date(today.getFullYear(), today.getMonth(), 1);

      const thisMonthCount = await MeterInfo.count({
        where: {
          IsActive: 1,
          CreateDate: {
            [Op.gte]: this.formatDate(monthStart)
          }
        }
      });

      return {
        total,
        draft: 0, // MeterInfo_test only has synced data
        pending,
        uploaded: total, // All records in MeterInfo_test are uploaded
        synced,
        withLocation,
        today: todayCount,
        thisWeek: thisWeekCount,
        thisMonth: thisMonthCount
      };
    } catch (error) {
      console.error('CMO statistics error:', error);
      throw error;
    }
  }

  /**
   * Get total user count from AdminSecurity table
   */
  async getUserCount() {
    try {
      const count = await AdminSecurity.count();
      return count;
    } catch (error) {
      console.error('User count error:', error);
      return 0;
    }
  }

  /**
   * Get customer count (unique customers from MeterInfo_test)
   */
  async getCustomerCount() {
    try {
      const result = await MeterInfo.count({
        where: { IsActive: 1 },
        distinct: true,
        col: 'CustomerId'
      });
      return result;
    } catch (error) {
      console.error('Customer count error:', error);
      return 0;
    }
  }

  /**
   * Get top users by CMO count
   */
  async getTopUsersByCMOCount(limit = 5) {
    try {
      // Query to get top users with their CMO count
      const results = await sequelize.query(`
        SELECT TOP ${limit}
          a.SecurityId,
          a.UserId as username,
          a.UserName as fullName,
          COUNT(m.Id) as cmo_count
        FROM AdminSecurity a
        LEFT JOIN MeterInfo_test m ON a.SecurityId = m.CreateBy AND m.IsActive = 1
        GROUP BY a.SecurityId, a.UserId, a.UserName
        HAVING COUNT(m.Id) > 0
        ORDER BY cmo_count DESC
      `, {
        type: sequelize.QueryTypes.SELECT
      });

      return results.map(row => ({
        username: row.username,
        fullName: row.fullName || row.username,
        cmo_count: row.cmo_count
      }));
    } catch (error) {
      console.error('Top users error:', error);
      return [];
    }
  }

  /**
   * Get CMO count for last 7 days
   */
  async getWeeklyData() {
    try {
      const weeklyData = {};
      const today = new Date();

      // Generate last 7 days
      for (let i = 6; i >= 0; i--) {
        const date = new Date(today);
        date.setDate(today.getDate() - i);
        const dateStr = this.formatDateKey(date);

        const nextDate = new Date(date);
        nextDate.setDate(date.getDate() + 1);

        const count = await MeterInfo.count({
          where: {
            IsActive: 1,
            CreateDate: {
              [Op.gte]: this.formatDate(date),
              [Op.lt]: this.formatDate(nextDate)
            }
          }
        });

        weeklyData[dateStr] = count;
      }

      return weeklyData;
    } catch (error) {
      console.error('Weekly data error:', error);
      return {};
    }
  }

  /**
   * Format date for SQL Server query (YYYY-MM-DD)
   */
  formatDate(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  /**
   * Format date key for response (YYYY-MM-DD)
   */
  formatDateKey(date) {
    return this.formatDate(date);
  }
}

module.exports = new ReportService();
