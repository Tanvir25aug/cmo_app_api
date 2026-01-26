# CMO API - Testing Guide

## 🧪 Quick API Testing Guide

### Prerequisites
- API is running on `http://localhost:8080`
- Use Postman, curl, or any HTTP client

---

## 📝 Test Sequence

### 1. Health Check

**Request:**
```bash
GET http://localhost:8080/api/health
```

**Expected Response:**
```json
{
  "success": true,
  "message": "CMO API is running",
  "timestamp": "2025-12-25T10:00:00.000Z",
  "environment": "development"
}
```

---

### 2. Register User

**Request:**
```bash
POST http://localhost:8080/api/auth/register
Content-Type: application/json

{
  "username": "testuser",
  "email": "test@example.com",
  "password": "password123",
  "fullName": "Test User",
  "phone": "01712345678"
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": "uuid-here",
      "username": "testuser",
      "email": "test@example.com",
      "fullName": "Test User",
      "phone": "01712345678",
      "role": "user",
      "isActive": true
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

**Save the `accessToken` for next requests!**

---

### 3. Login

**Request:**
```bash
POST http://localhost:8080/api/auth/login
Content-Type: application/json

{
  "email": "test@example.com",
  "password": "password123"
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": { ... },
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

---

### 4. Get Profile (Protected)

**Request:**
```bash
GET http://localhost:8080/api/auth/profile
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Profile retrieved successfully",
  "data": {
    "id": "uuid-here",
    "username": "testuser",
    "email": "test@example.com",
    "fullName": "Test User"
  }
}
```

---

### 5. Create CMO Request

**Request:**
```bash
POST http://localhost:8080/api/cmo
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json

{
  "customerId": "CUST001",
  "newMeterId": "METER001",
  "customerName": "John Doe",
  "mobileNumber": "01712345678",
  "email": "john@example.com",
  "flatNo": "A-101",
  "floor": "1st",
  "nid": "1234567890",
  "oldMeterType": "1P",
  "oldMeterNumber": "OLD123",
  "oldMeterReading": "1000",
  "status": "draft"
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "CMO created successfully",
  "data": {
    "id": "cmo-uuid-here",
    "customerId": "CUST001",
    "customerName": "John Doe",
    "status": "draft",
    "createdAt": "2025-12-25T10:00:00.000Z"
  }
}
```

---

### 6. Get All CMOs

**Request:**
```bash
GET http://localhost:8080/api/cmo
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Query Parameters:**
- `page=1` - Page number
- `limit=20` - Items per page
- `status=draft` - Filter by status
- `search=John` - Search by name, mobile, etc.

**Expected Response:**
```json
{
  "success": true,
  "message": "CMOs retrieved successfully",
  "data": [ ... ],
  "pagination": {
    "total": 5,
    "page": 1,
    "limit": 20,
    "totalPages": 1
  }
}
```

---

### 7. Get CMO by ID

**Request:**
```bash
GET http://localhost:8080/api/cmo/{cmo-id}
Authorization: Bearer YOUR_ACCESS_TOKEN
```

---

### 8. Update CMO

**Request:**
```bash
PUT http://localhost:8080/api/cmo/{cmo-id}
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json

{
  "status": "pending",
  "oldMeterReading": "1500"
}
```

---

### 9. Get Statistics

**Request:**
```bash
GET http://localhost:8080/api/cmo/statistics
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Statistics retrieved successfully",
  "data": {
    "total": 10,
    "draft": 3,
    "pending": 5,
    "uploaded": 2,
    "approved": 0
  }
}
```

---

### 10. Sync CMOs (Bulk Upload)

**Request:**
```bash
POST http://localhost:8080/api/cmo/sync
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json

{
  "cmos": [
    {
      "customerName": "Jane Smith",
      "mobileNumber": "01798765432",
      "customerId": "CUST002",
      "status": "draft"
    },
    {
      "customerName": "Bob Wilson",
      "mobileNumber": "01612345678",
      "customerId": "CUST003",
      "status": "pending"
    }
  ]
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Sync completed",
  "data": {
    "success": [
      {
        "clientId": null,
        "serverId": "uuid-1",
        "status": "synced"
      },
      {
        "clientId": null,
        "serverId": "uuid-2",
        "status": "synced"
      }
    ],
    "failed": []
  }
}
```

---

## 🐛 Common Errors

### 401 Unauthorized
```json
{
  "success": false,
  "message": "No authentication token provided"
}
```
**Solution**: Add `Authorization: Bearer YOUR_TOKEN` header

### 400 Validation Error
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    {
      "type": "field",
      "msg": "Customer name is required",
      "path": "customerName"
    }
  ]
}
```
**Solution**: Check required fields in request body

### 404 Not Found
```json
{
  "success": false,
  "message": "CMO request not found"
}
```
**Solution**: Check if the CMO ID exists and belongs to the user

---

## 📦 Postman Collection

### Import Steps:
1. Open Postman
2. Click Import
3. Select file or paste JSON below
4. Collection will be imported with all endpoints

### Quick Collection JSON:
```json
{
  "info": {
    "name": "CMO API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "variable": [
    {
      "key": "base_url",
      "value": "http://localhost:8080/api"
    },
    {
      "key": "token",
      "value": "YOUR_ACCESS_TOKEN"
    }
  ],
  "item": [
    {
      "name": "Auth",
      "item": [
        {
          "name": "Register",
          "request": {
            "method": "POST",
            "header": [],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"username\": \"testuser\",\n  \"email\": \"test@example.com\",\n  \"password\": \"password123\",\n  \"fullName\": \"Test User\"\n}",
              "options": {
                "raw": {
                  "language": "json"
                }
              }
            },
            "url": {
              "raw": "{{base_url}}/auth/register",
              "host": ["{{base_url}}"],
              "path": ["auth", "register"]
            }
          }
        },
        {
          "name": "Login",
          "request": {
            "method": "POST",
            "header": [],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"email\": \"test@example.com\",\n  \"password\": \"password123\"\n}",
              "options": {
                "raw": {
                  "language": "json"
                }
              }
            },
            "url": {
              "raw": "{{base_url}}/auth/login",
              "host": ["{{base_url}}"],
              "path": ["auth", "login"]
            }
          }
        }
      ]
    },
    {
      "name": "CMO",
      "item": [
        {
          "name": "Get All CMOs",
          "request": {
            "method": "GET",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{token}}"
              }
            ],
            "url": {
              "raw": "{{base_url}}/cmo",
              "host": ["{{base_url}}"],
              "path": ["cmo"]
            }
          }
        },
        {
          "name": "Create CMO",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{token}}"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"customerName\": \"John Doe\",\n  \"mobileNumber\": \"01712345678\",\n  \"status\": \"draft\"\n}",
              "options": {
                "raw": {
                  "language": "json"
                }
              }
            },
            "url": {
              "raw": "{{base_url}}/cmo",
              "host": ["{{base_url}}"],
              "path": ["cmo"]
            }
          }
        }
      ]
    }
  ]
}
```

---

## 🔧 Testing Tools

### Using curl (Command Line)

```bash
# Health check
curl http://localhost:8080/api/health

# Register
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"password123"}'

# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Get CMOs (with token)
curl http://localhost:8080/api/cmo \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Using PowerShell

```powershell
# Health check
Invoke-RestMethod -Uri "http://localhost:8080/api/health"

# Login
$body = @{
    email = "test@example.com"
    password = "password123"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" `
    -Method Post `
    -ContentType "application/json" `
    -Body $body

$token = $response.data.accessToken

# Get CMOs
$headers = @{
    Authorization = "Bearer $token"
}

Invoke-RestMethod -Uri "http://localhost:8080/api/cmo" `
    -Headers $headers
```

---

**Happy Testing! 🚀**
