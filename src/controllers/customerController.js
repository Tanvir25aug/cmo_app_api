const customerService = require('../services/customerService');
const { successResponse, errorResponse } = require('../utils/response');
const logger = require('../utils/logger');

class CustomerController {
  /**
   * Get customer by OLD_CONSUMER_ID
   * GET /api/customer/:id
   */
  async getById(req, res) {
    try {
      const { id } = req.params;

      // Validate customer ID (8 digits)
      if (!id || !/^\d{8}$/.test(id)) {
        return errorResponse(res, 'Customer ID must be exactly 8 digits', 400);
      }

      const customer = await customerService.getCustomerById(id);
      return successResponse(res, customer, 'Customer found');
    } catch (error) {
      logger.error(`Get customer error: ${error.message}`);

      if (error.message === 'Customer not found') {
        return errorResponse(res, 'Customer not found', 404);
      }

      return errorResponse(res, error.message, 500);
    }
  }

  /**
   * Get total customer count
   * GET /api/customers/count
   */
  async getCount(req, res) {
    try {
      const totalCount = await customerService.getCustomerCount();
      const last5000Count = await customerService.getLast5000Count();

      return successResponse(
        res,
        {
          total: totalCount,
          last5000: last5000Count,
          count: last5000Count // For backwards compatibility
        },
        'Customer count retrieved'
      );
    } catch (error) {
      logger.error(`Get customer count error: ${error.message}`);
      return errorResponse(res, error.message, 500);
    }
  }

  /**
   * Sync last 5000 customers (paginated download for offline use)
   * GET /api/customers/sync?limit=100&offset=0
   */
  async sync(req, res) {
    try {
      const limit = parseInt(req.query.limit) || 100;
      const offset = parseInt(req.query.offset) || 0;

      // Validate pagination parameters
      if (limit < 1 || limit > 1000) {
        return errorResponse(res, 'Limit must be between 1 and 1000', 400);
      }

      if (offset < 0) {
        return errorResponse(res, 'Offset must be 0 or greater', 400);
      }

      // Only sync last 5000 customers
      const result = await customerService.syncLast5000Customers(limit, offset);

      logger.info(`Customer sync: ${result.synced} of last 5000 customers sent (offset: ${offset})`);

      return successResponse(
        res,
        result,
        `Retrieved ${result.synced} of ${result.total} customers (Last 5000)`
      );
    } catch (error) {
      logger.error(`Sync customers error: ${error.message}`);
      return errorResponse(res, error.message, 500);
    }
  }

  /**
   * Search customers by name, ID, or mobile
   * GET /api/customers/search?q=searchterm
   */
  async search(req, res) {
    try {
      const { q } = req.query;

      if (!q || q.trim().length < 2) {
        return errorResponse(res, 'Search term must be at least 2 characters', 400);
      }

      const limit = parseInt(req.query.limit) || 20;
      const customers = await customerService.searchCustomers(q, limit);

      return successResponse(
        res,
        { customers, count: customers.length },
        `Found ${customers.length} customers`
      );
    } catch (error) {
      logger.error(`Search customers error: ${error.message}`);
      return errorResponse(res, error.message, 500);
    }
  }

  /**
   * Get customers by zone (optional - for filtered sync)
   * GET /api/customers/zone/:zoneCode?limit=100&offset=0
   */
  async getByZone(req, res) {
    try {
      const { zoneCode } = req.params;
      const limit = parseInt(req.query.limit) || 100;
      const offset = parseInt(req.query.offset) || 0;

      if (!zoneCode) {
        return errorResponse(res, 'Zone code is required', 400);
      }

      const result = await customerService.getCustomersByZone(zoneCode, limit, offset);

      return successResponse(
        res,
        result,
        `Retrieved ${result.synced} customers from zone ${zoneCode}`
      );
    } catch (error) {
      logger.error(`Get customers by zone error: ${error.message}`);
      return errorResponse(res, error.message, 500);
    }
  }

  /**
   * Health check for customer service
   * GET /api/customers/health
   */
  async healthCheck(req, res) {
    try {
      const count = await customerService.getCustomerCount();
      return successResponse(
        res,
        {
          status: 'healthy',
          totalCustomers: count,
          timestamp: new Date().toISOString()
        },
        'Customer service is healthy'
      );
    } catch (error) {
      logger.error(`Customer health check error: ${error.message}`);
      return errorResponse(
        res,
        'Customer service is unhealthy',
        503,
        { error: error.message }
      );
    }
  }
}

module.exports = new CustomerController();
