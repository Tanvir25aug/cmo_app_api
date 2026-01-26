const { sequelize } = require('../config/database');
const logger = require('../utils/logger');

class CustomerService {
  /**
   * Get customer by OLD_CONSUMER_ID
   */
  async getCustomerById(oldConsumerId) {
    try {
      const query = `
        SELECT
          [ID],
          [INDEX_NO],
          [OLD_CONSUMER_ID],
          [CUSTOMER_NAME],
          [ADDRESS],
          [FLOOR_NO],
          [FLAT_NO],
          [PASSPORT],
          [BIRTH_CERTIFICATE],
          [NID],
          [MOBILE_NO],
          [CHANGED_MOBILE_NO],
          [SECONDARY_MOBILE_NO],
          [EMAIL_ID],
          [FATHER_NAME],
          [MOTHER_NAME],
          [SPOUSE_NAME],
          [DOB],
          [MAILING_COUNTRY],
          [MAILING_POSTAL_CODE],
          [MAILING_DISTRICT],
          [PREMISE_TYPE],
          [COUNTRY],
          [POSTAL_CODE],
          [DISTRICT],
          [THANA],
          [AREA],
          [ZONE],
          [ZONE_CODE],
          [CIRCLE],
          [CIRCLE_CODE],
          [NOCS],
          [NOCS_CODE],
          [SECTOR],
          [CUSTOMER_CREATED_DT],
          [BILL_ROUTE_TYPE],
          [RELATIONSHIP_TYPE],
          [BILL_GROUP],
          [OLD_NEW_CUSTOMER],
          [VIP_CUSTOMER],
          [CONNECTION_TYPE],
          [OLD_ACCOUNT_NO],
          [METER_OWNER],
          [METER_TYPE],
          [METER_TYPE_REMARKS],
          [TRANSFORMER_OWNER],
          [TRANSFORMER_SIDE],
          [CPC_CPR],
          [CPR_CONSUMER_ID],
          [LIKELY_CONSUMPTION],
          [WALK_ORDER],
          [BOOK],
          [NETMETER_FLAG],
          [XFORMER_CD],
          [METERING_MODE],
          [OMF],
          [CUST_TARIFF_CATEGORY],
          [SANCTIONED_LOAD],
          [CONNECTED_LOAD],
          [BUSINESS_TYPE],
          [BUSINESS_TYPE_DESC],
          [NO_OF_SPM_CUST],
          [VAT_REBATE],
          [SPECIAL_CATEGORY],
          [STATUS_CODE],
          [MINISTRY],
          [ORGANIZATION],
          [DMD_CHARGE_AFT_MIGR],
          [SUB_STATION_CD],
          [SUB_STATION_NAME],
          [FEEDER_CD],
          [FEEDER_NAME]
        FROM [MeterOCRDESCO].[dbo].[Customer]
        WHERE [OLD_CONSUMER_ID] = :oldConsumerId
      `;

      const [results] = await sequelize.query(query, {
        replacements: { oldConsumerId },
        type: sequelize.QueryTypes.SELECT
      });

      if (!results) {
        throw new Error('Customer not found');
      }

      logger.info(`Customer found: ${oldConsumerId}`);
      return results;
    } catch (error) {
      logger.error(`Get customer error: ${error.message}`);
      throw error;
    }
  }

  /**
   * Get total customer count
   */
  async getCustomerCount() {
    try {
      const query = `
        SELECT COUNT(*) as count
        FROM [MeterOCRDESCO].[dbo].[Customer]
      `;

      const [result] = await sequelize.query(query, {
        type: sequelize.QueryTypes.SELECT
      });

      return result.count;
    } catch (error) {
      logger.error(`Get customer count error: ${error.message}`);
      throw error;
    }
  }

  /**
   * Get count of last 5000 customers (for offline sync)
   */
  async getLast5000Count() {
    try {
      // Always return 5000 or less if total is less than 5000
      const totalCount = await this.getCustomerCount();
      return Math.min(totalCount, 5000);
    } catch (error) {
      logger.error(`Get last 5000 count error: ${error.message}`);
      throw error;
    }
  }

  /**
   * Sync last 5000 customers (for offline use)
   * Orders by ID DESC to get most recent customers
   */
  async syncLast5000Customers(limit = 100, offset = 0) {
    try {
      // Maximum 5000 customers for offline sync
      const maxOfflineCustomers = 5000;
      const totalCount = await this.getLast5000Count();

      // Get paginated customers from the last 5000
      const query = `
        WITH Last5000 AS (
          SELECT TOP 5000
            [ID],
            [INDEX_NO],
            [OLD_CONSUMER_ID],
            [CUSTOMER_NAME],
            [ADDRESS],
            [FLOOR_NO],
            [FLAT_NO],
            [PASSPORT],
            [BIRTH_CERTIFICATE],
            [NID],
            [MOBILE_NO],
            [CHANGED_MOBILE_NO],
            [SECONDARY_MOBILE_NO],
            [EMAIL_ID],
            [FATHER_NAME],
            [MOTHER_NAME],
            [SPOUSE_NAME],
            [DOB],
            [MAILING_COUNTRY],
            [MAILING_POSTAL_CODE],
            [MAILING_DISTRICT],
            [PREMISE_TYPE],
            [COUNTRY],
            [POSTAL_CODE],
            [DISTRICT],
            [THANA],
            [AREA],
            [ZONE],
            [ZONE_CODE],
            [CIRCLE],
            [CIRCLE_CODE],
            [NOCS],
            [NOCS_CODE],
            [SECTOR],
            [CUSTOMER_CREATED_DT],
            [BILL_ROUTE_TYPE],
            [RELATIONSHIP_TYPE],
            [BILL_GROUP],
            [OLD_NEW_CUSTOMER],
            [VIP_CUSTOMER],
            [CONNECTION_TYPE],
            [OLD_ACCOUNT_NO],
            [METER_OWNER],
            [METER_TYPE],
            [METER_TYPE_REMARKS],
            [TRANSFORMER_OWNER],
            [TRANSFORMER_SIDE],
            [CPC_CPR],
            [CPR_CONSUMER_ID],
            [LIKELY_CONSUMPTION],
            [WALK_ORDER],
            [BOOK],
            [NETMETER_FLAG],
            [XFORMER_CD],
            [METERING_MODE],
            [OMF],
            [CUST_TARIFF_CATEGORY],
            [SANCTIONED_LOAD],
            [CONNECTED_LOAD],
            [BUSINESS_TYPE],
            [BUSINESS_TYPE_DESC],
            [NO_OF_SPM_CUST],
            [VAT_REBATE],
            [SPECIAL_CATEGORY],
            [STATUS_CODE],
            [MINISTRY],
            [ORGANIZATION],
            [DMD_CHARGE_AFT_MIGR],
            [SUB_STATION_CD],
            [SUB_STATION_NAME],
            [FEEDER_CD],
            [FEEDER_NAME]
          FROM [MeterOCRDESCO].[dbo].[Customer]
          ORDER BY [ID] DESC
        )
        SELECT *
        FROM Last5000
        ORDER BY [OLD_CONSUMER_ID]
        OFFSET :offset ROWS
        FETCH NEXT :limit ROWS ONLY
      `;

      const customers = await sequelize.query(query, {
        replacements: { limit, offset },
        type: sequelize.QueryTypes.SELECT
      });

      logger.info(`Synced ${customers.length} of last 5000 customers (offset: ${offset}, limit: ${limit})`);

      return {
        customers,
        total: totalCount,
        synced: customers.length,
        offset,
        limit,
        isLast5000: true
      };
    } catch (error) {
      logger.error(`Sync last 5000 customers error: ${error.message}`);
      throw error;
    }
  }

  /**
   * Search customers by name or ID (optional feature)
   */
  async searchCustomers(searchTerm, limit = 20) {
    try {
      const query = `
        SELECT TOP (:limit)
          [ID],
          [INDEX_NO],
          [OLD_CONSUMER_ID],
          [CUSTOMER_NAME],
          [ADDRESS],
          [MOBILE_NO],
          [NID],
          [NOCS],
          [FEEDER_NAME],
          [BILL_GROUP]
        FROM [MeterOCRDESCO].[dbo].[Customer]
        WHERE
          [OLD_CONSUMER_ID] LIKE :searchTerm OR
          [CUSTOMER_NAME] LIKE :searchTerm OR
          [MOBILE_NO] LIKE :searchTerm
        ORDER BY [CUSTOMER_NAME]
      `;

      const customers = await sequelize.query(query, {
        replacements: {
          limit,
          searchTerm: `%${searchTerm}%`
        },
        type: sequelize.QueryTypes.SELECT
      });

      logger.info(`Search found ${customers.length} customers for term: ${searchTerm}`);
      return customers;
    } catch (error) {
      logger.error(`Search customers error: ${error.message}`);
      throw error;
    }
  }

  /**
   * Get customers by zone/area (optional feature for filtered sync)
   */
  async getCustomersByZone(zoneCode, limit = 100, offset = 0) {
    try {
      const countQuery = `
        SELECT COUNT(*) as count
        FROM [MeterOCRDESCO].[dbo].[Customer]
        WHERE [ZONE_CODE] = :zoneCode
      `;

      const [countResult] = await sequelize.query(countQuery, {
        replacements: { zoneCode },
        type: sequelize.QueryTypes.SELECT
      });

      const query = `
        SELECT
          [ID],
          [INDEX_NO],
          [OLD_CONSUMER_ID],
          [CUSTOMER_NAME],
          [ADDRESS],
          [FLOOR_NO],
          [FLAT_NO],
          [MOBILE_NO],
          [SECONDARY_MOBILE_NO],
          [EMAIL_ID],
          [NID],
          [NOCS],
          [FEEDER_NAME],
          [BILL_GROUP],
          [SANCTIONED_LOAD],
          [BOOK],
          [CUST_TARIFF_CATEGORY],
          [ZONE],
          [ZONE_CODE],
          [CIRCLE],
          [AREA]
        FROM [MeterOCRDESCO].[dbo].[Customer]
        WHERE [ZONE_CODE] = :zoneCode
        ORDER BY [OLD_CONSUMER_ID]
        OFFSET :offset ROWS
        FETCH NEXT :limit ROWS ONLY
      `;

      const customers = await sequelize.query(query, {
        replacements: { zoneCode, limit, offset },
        type: sequelize.QueryTypes.SELECT
      });

      return {
        customers,
        total: countResult.count,
        synced: customers.length,
        zone: zoneCode
      };
    } catch (error) {
      logger.error(`Get customers by zone error: ${error.message}`);
      throw error;
    }
  }
}

module.exports = new CustomerService();
