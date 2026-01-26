const jwt = require('jsonwebtoken');
const { jwtSecret } = require('../config/auth');
const { AdminSecurity } = require('../models');
const { errorResponse } = require('../utils/response');

const auth = async (req, res, next) => {
  try {
    // Get token from header
    const token = req.header('Authorization')?.replace('Bearer ', '');

    if (!token) {
      return errorResponse(res, 'No authentication token provided', 401);
    }

    // Verify token
    const decoded = jwt.verify(token, jwtSecret);

    // Find user by SecurityId (primary key)
    const user = await AdminSecurity.findByPk(decoded.id);

    if (!user) {
      return errorResponse(res, 'Invalid token or user not found', 401);
    }

    // Attach user to request
    req.user = user;
    req.userId = user.UserId; // Use UserId field for CMO relations
    req.securityId = user.SecurityId; // SecurityId (primary key)

    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return errorResponse(res, 'Invalid token', 401);
    }
    if (error.name === 'TokenExpiredError') {
      return errorResponse(res, 'Token expired', 401);
    }
    return errorResponse(res, 'Authentication failed', 401);
  }
};

// Optional auth (doesn't fail if no token)
const optionalAuth = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');

    if (token) {
      const decoded = jwt.verify(token, jwtSecret);
      const user = await AdminSecurity.findByPk(decoded.id);
      if (user) {
        req.user = user;
        req.userId = user.UserId;
        req.securityId = user.SecurityId;
      }
    }

    next();
  } catch (error) {
    next();
  }
};

// Role-based authorization
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return errorResponse(res, 'Not authenticated', 401);
    }

    if (!roles.includes(req.user.role)) {
      return errorResponse(res, 'Insufficient permissions', 403);
    }

    next();
  };
};

module.exports = { auth, optionalAuth, authorize };
