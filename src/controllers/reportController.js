const reportService = require('../services/reportService');
const { successResponse, errorResponse } = require('../utils/response');

class ReportController {
  /**
   * GET /reports/dashboard
   * Get complete dashboard data in one call
   */
  async getDashboardData(req, res) {
    try {
      const data = await reportService.getDashboardData();

      return successResponse(res, data, 'Dashboard data retrieved successfully');
    } catch (error) {
      console.error('Dashboard data error:', error);
      return errorResponse(res, 'Failed to retrieve dashboard data', 500);
    }
  }

  /**
   * GET /reports/cmo-statistics
   * Get CMO statistics
   */
  async getCMOStatistics(req, res) {
    try {
      const stats = await reportService.getCMOStatistics();

      return successResponse(res, stats, 'CMO statistics retrieved successfully');
    } catch (error) {
      console.error('CMO statistics error:', error);
      return errorResponse(res, 'Failed to retrieve CMO statistics', 500);
    }
  }

  /**
   * GET /reports/user-statistics
   * Get user statistics
   */
  async getUserStatistics(req, res) {
    try {
      const userCount = await reportService.getUserCount();

      return successResponse(res, { userCount }, 'User statistics retrieved successfully');
    } catch (error) {
      console.error('User statistics error:', error);
      return errorResponse(res, 'Failed to retrieve user statistics', 500);
    }
  }

  /**
   * GET /reports/top-users
   * Get top users by CMO count
   */
  async getTopUsers(req, res) {
    try {
      const limit = parseInt(req.query.limit) || 5;
      const users = await reportService.getTopUsersByCMOCount(limit);

      return successResponse(res, { users }, 'Top users retrieved successfully');
    } catch (error) {
      console.error('Top users error:', error);
      return errorResponse(res, 'Failed to retrieve top users', 500);
    }
  }

  /**
   * GET /reports/weekly-data
   * Get CMO count for last 7 days
   */
  async getWeeklyData(req, res) {
    try {
      const weeklyData = await reportService.getWeeklyData();

      return successResponse(res, { weeklyData }, 'Weekly data retrieved successfully');
    } catch (error) {
      console.error('Weekly data error:', error);
      return errorResponse(res, 'Failed to retrieve weekly data', 500);
    }
  }

  /**
   * GET /reports/customer-count
   * Get total customer count
   */
  async getCustomerCount(req, res) {
    try {
      const count = await reportService.getCustomerCount();

      return successResponse(res, { count }, 'Customer count retrieved successfully');
    } catch (error) {
      console.error('Customer count error:', error);
      return errorResponse(res, 'Failed to retrieve customer count', 500);
    }
  }
}

module.exports = new ReportController();
