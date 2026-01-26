# Customer API Implementation Guide

## Overview
Backend API endpoints for customer search and synchronization functionality with offline support for the CMO Flutter application.

## Implementation Summary

### Files Created
1. **`src/services/customerService.js`** - Business logic and database queries
2. **`src/controllers/customerController.js`** - HTTP request handlers
3. **`src/routes/customer.js`** - Route definitions

### Files Modified
1. **`src/routes/index.js`** - Added customer routes
2. **`src/app.js`** - Updated endpoint documentation

## API Endpoints

### 1. Get Customer by ID
**Endpoint:** `GET /api/customer/:id`
**Authentication:** Required (JWT)
**Description:** Get customer details by OLD_CONSUMER_ID

**Parameters:**
- `id` (path parameter): 8-digit customer ID

**Example Request:**
```bash
curl -X GET \
  http://172.16.20.102:8080/api/customer/12345678 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Customer found",
  "data": {
    "ID": 123,
    "OLD_CONSUMER_ID": "12345678",
    "CUSTOMER_NAME": "John Doe",
    "MOBILE_NO": "01712345678",
    "FLAT_NO": "5A",
    "FLOOR_NO": "5",
    "NID": "1234567890",
    "NOCS": "NOCS123",
    "FEEDER_NAME": "Feeder A",
    "BILL_GROUP": "Group 1",
    "SANCTIONED_LOAD": "5.5",
    "BOOK": "Book 1",
    "CUST_TARIFF_CATEGORY": "Residential",
    ... (all other 72 fields)
  }
}
```

**Error Response (404):**
```json
{
  "success": false,
  "message": "Customer not found"
}
```

**Validation:**
- Customer ID must be exactly 8 digits
- Returns 400 if validation fails

---

### 2. Get Customer Count
**Endpoint:** `GET /api/customers/count`
**Authentication:** Required (JWT)
**Description:** Get total number of customers in database

**Example Request:**
```bash
curl -X GET \
  http://172.16.20.102:8080/api/customers/count \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Customer count retrieved",
  "data": {
    "count": 5000
  }
}
```

---

### 3. Sync Customers (Paginated)
**Endpoint:** `GET /api/customers/sync?limit=100&offset=0`
**Authentication:** Required (JWT)
**Description:** Download customers in batches for offline storage

**Query Parameters:**
- `limit` (optional): Number of records per page (default: 100, max: 1000)
- `offset` (optional): Number of records to skip (default: 0)

**Example Request:**
```bash
# First batch
curl -X GET \
  "http://172.16.20.102:8080/api/customers/sync?limit=100&offset=0" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Second batch
curl -X GET \
  "http://172.16.20.102:8080/api/customers/sync?limit=100&offset=100" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Retrieved 100 of 5000 customers",
  "data": {
    "customers": [
      {
        "ID": 123,
        "OLD_CONSUMER_ID": "12345678",
        "CUSTOMER_NAME": "John Doe",
        ... (all fields)
      },
      ... (99 more customers)
    ],
    "total": 5000,
    "synced": 100,
    "offset": 0,
    "limit": 100
  }
}
```

**Validation:**
- Limit must be between 1 and 1000
- Offset must be 0 or greater
- Returns 400 if validation fails

---

### 4. Search Customers
**Endpoint:** `GET /api/customers/search?q=searchterm`
**Authentication:** Required (JWT)
**Description:** Search customers by name, ID, or mobile number

**Query Parameters:**
- `q`: Search term (minimum 2 characters)
- `limit` (optional): Max results to return (default: 20)

**Example Request:**
```bash
curl -X GET \
  "http://172.16.20.102:8080/api/customers/search?q=John&limit=10" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Found 5 customers",
  "data": {
    "customers": [
      {
        "ID": 123,
        "OLD_CONSUMER_ID": "12345678",
        "CUSTOMER_NAME": "John Doe",
        "ADDRESS": "123 Main St",
        "MOBILE_NO": "01712345678",
        "NID": "1234567890",
        "NOCS": "NOCS123",
        "FEEDER_NAME": "Feeder A",
        "BILL_GROUP": "Group 1"
      },
      ...
    ],
    "count": 5
  }
}
```

---

### 5. Get Customers by Zone (Optional)
**Endpoint:** `GET /api/customers/zone/:zoneCode?limit=100&offset=0`
**Authentication:** Required (JWT)
**Description:** Get customers filtered by zone code

**Parameters:**
- `zoneCode` (path): Zone code to filter by
- `limit` (query): Records per page (default: 100)
- `offset` (query): Records to skip (default: 0)

**Example Request:**
```bash
curl -X GET \
  "http://172.16.20.102:8080/api/customers/zone/ZONE01?limit=50&offset=0" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Retrieved 50 customers from zone ZONE01",
  "data": {
    "customers": [...],
    "total": 150,
    "synced": 50,
    "zone": "ZONE01"
  }
}
```

---

### 6. Customer Service Health Check
**Endpoint:** `GET /api/customers/health`
**Authentication:** Required (JWT)
**Description:** Check if customer service is operational

**Example Request:**
```bash
curl -X GET \
  http://172.16.20.102:8080/api/customers/health \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Customer service is healthy",
  "data": {
    "status": "healthy",
    "totalCustomers": 5000,
    "timestamp": "2025-01-02T12:00:00.000Z"
  }
}
```

## Database Schema

**Table:** `[MeterOCRDESCO].[dbo].[Customer]`

**Key Fields Used:**
- `OLD_CONSUMER_ID` - Primary search key (8 digits)
- `CUSTOMER_NAME` - Customer's full name
- `MOBILE_NO` - Primary mobile number
- `SECONDARY_MOBILE_NO` - Secondary contact
- `EMAIL_ID` - Email address
- `FLAT_NO` - Flat/apartment number
- `FLOOR_NO` - Floor number
- `NID` - National ID number
- `NOCS` - NOCS code
- `FEEDER_NAME` - Electrical feeder name
- `BILL_GROUP` - Billing group
- `SANCTIONED_LOAD` - Sanctioned electrical load
- `BOOK` - Book number
- `CUST_TARIFF_CATEGORY` - Tariff category

**Total Fields:** 72 (all mapped in the service)

## Service Layer (customerService.js)

### Methods

#### `getCustomerById(oldConsumerId)`
- Fetches single customer by OLD_CONSUMER_ID
- Returns all 72 fields
- Throws error if not found

#### `getCustomerCount()`
- Returns total number of customers
- Used for sync progress calculation

#### `syncCustomers(limit, offset)`
- Fetches customers in batches
- Returns paginated data with metadata
- Orders by OLD_CONSUMER_ID

#### `searchCustomers(searchTerm, limit)`
- Searches by name, ID, or mobile
- Uses SQL LIKE operator
- Returns top N results

#### `getCustomersByZone(zoneCode, limit, offset)`
- Filters customers by zone
- Useful for zone-specific syncing
- Returns paginated results

## Controller Layer (customerController.js)

### Responsibilities
- Request validation
- Error handling
- Response formatting
- Logging

### Validation Rules
- Customer ID: Must be exactly 8 digits
- Search term: Minimum 2 characters
- Limit: Between 1 and 1000
- Offset: 0 or greater

## Security

**Authentication:** All endpoints require valid JWT token

**Headers Required:**
```
Authorization: Bearer <JWT_TOKEN>
```

**Token Validation:**
- Handled by `auth` middleware
- Must be obtained via `/api/auth/login`
- Token must not be expired

## Error Handling

### Standard Error Response
```json
{
  "success": false,
  "message": "Error description"
}
```

### HTTP Status Codes
- `200` - Success
- `400` - Bad Request (validation error)
- `401` - Unauthorized (no/invalid token)
- `404` - Not Found (customer doesn't exist)
- `500` - Internal Server Error
- `503` - Service Unavailable (health check failed)

## Logging

All operations are logged with:
- Info level: Successful operations
- Error level: Failures and exceptions

**Log Format:**
```
[timestamp] info: Customer found: 12345678
[timestamp] error: Get customer error: Customer not found
```

## Testing the API

### 1. Test Connection
```bash
curl http://172.16.20.102:8080/api/health
```

### 2. Login to Get Token
```bash
curl -X POST http://172.16.20.102:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"your_username","password":"your_password"}'
```

### 3. Test Customer Endpoints
```bash
# Get count
curl -X GET http://172.16.20.102:8080/api/customers/count \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get customer
curl -X GET http://172.16.20.102:8080/api/customer/12345678 \
  -H "Authorization: Bearer YOUR_TOKEN"

# Sync customers
curl -X GET "http://172.16.20.102:8080/api/customers/sync?limit=10&offset=0" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Performance Considerations

### Indexing
Ensure SQL Server has indexes on:
- `OLD_CONSUMER_ID` (primary key/unique)
- `CUSTOMER_NAME` (for search)
- `MOBILE_NO` (for search)
- `ZONE_CODE` (for zone filtering)

### Pagination
- Default page size: 100 customers
- Maximum page size: 1000 customers
- Use offset-based pagination for simple implementation

### Optimization Tips
1. Add database indexes on frequently searched columns
2. Use connection pooling (already configured in database.js)
3. Consider caching customer count if it doesn't change frequently
4. Monitor query performance for large datasets

## Integration with Flutter App

The Flutter app (`customer_api_service.dart`) calls these endpoints:

1. **Customer Search**: `/api/customer/:id`
   - Triggered when user clicks "Search" button
   - Auto-saves result to local SQLite

2. **Customer Sync**: `/api/customers/sync`
   - Triggered from Settings > Sync Customer Data
   - Downloads in batches of 100
   - Shows progress to user

3. **Customer Count**: `/api/customers/count`
   - Used to calculate total sync progress
   - Displayed in Settings screen

## Deployment Checklist

- [ ] Environment variables configured in `.env`
- [ ] Database connection tested
- [ ] SQL Server accessible from API server
- [ ] JWT authentication working
- [ ] All endpoints tested with valid tokens
- [ ] Error handling verified
- [ ] Logging configured
- [ ] API server restarted after deployment

## Restart API Server

After adding these files, restart your API server:

```bash
# Using PM2 (if configured)
pm2 restart cmo-api

# Or using nodemon (development)
npm run dev

# Or direct node
node src/server.js
```

## Verify Deployment

Check logs for successful startup:
```
✅ Database connection established successfully.
📊 Connected to: MeterOCRDESCO on YOUR_SERVER
Server is running on port 8080
```

Test the customer endpoint:
```bash
curl http://172.16.20.102:8080/api/customers/health \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Support

For issues or questions:
1. Check logs: `pm2 logs cmo-api` or console output
2. Verify database connection
3. Ensure JWT token is valid
4. Check customer table exists and has data
5. Verify network connectivity from Flutter app to API

---

**Implementation Date:** 2026-01-02
**Version:** 1.0.0
**Status:** Ready for Production
