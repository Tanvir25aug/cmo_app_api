const authService = require('../services/authService');
const { successResponse, errorResponse } = require('../utils/response');
const logger = require('../utils/logger');

class AuthController {
  // Login with AdminSecurity table
  async login(req, res) {
    try {
      const { username, password, email } = req.body;
      // Support both 'username' and 'email' fields for backward compatibility
      const loginUsername = username || email;
      const result = await authService.login(loginUsername, password);
      logger.info(`User logged in: ${loginUsername}`);
      return successResponse(res, result, 'Login successful');
    } catch (error) {
      logger.error(`Login error: ${error.message}`);
      return errorResponse(res, error.message, 401);
    }
  }

  // Refresh Token
  async refreshToken(req, res) {
    try {
      const { refreshToken } = req.body;
      const result = await authService.refreshToken(refreshToken);
      return successResponse(res, result, 'Token refreshed successfully');
    } catch (error) {
      return errorResponse(res, error.message, 401);
    }
  }

  // Get Profile
  async getProfile(req, res) {
    try {
      const user = await authService.getProfile(req.userId);
      return successResponse(res, user, 'Profile retrieved successfully');
    } catch (error) {
      return errorResponse(res, error.message, 404);
    }
  }

  // Update Profile
  async updateProfile(req, res) {
    try {
      const user = await authService.updateProfile(req.userId, req.body);
      logger.info(`Profile updated: ${user.email}`);
      return successResponse(res, user, 'Profile updated successfully');
    } catch (error) {
      return errorResponse(res, error.message, 400);
    }
  }

  // Logout
  async logout(req, res) {
    try {
      // In a real app, you might want to blacklist the token
      logger.info(`User logged out: ${req.user.email}`);
      return successResponse(res, {}, 'Logged out successfully');
    } catch (error) {
      return errorResponse(res, error.message, 400);
    }
  }

  // ============ Admin User Management ============

  // Get all users (admin only)
  async getAllUsers(req, res) {
    try {
      // Check if requesting user is admin (use securityId - primary key)
      const isAdmin = await authService.isAdmin(req.securityId);
      if (!isAdmin) {
        return errorResponse(res, 'Admin access required', 403);
      }

      const users = await authService.getAllUsers();
      return successResponse(res, users, 'Users retrieved successfully');
    } catch (error) {
      logger.error(`Get all users error: ${error.message}`);
      return errorResponse(res, error.message, 500);
    }
  }

  // Create new user (admin only)
  async createUser(req, res) {
    try {
      // Check if requesting user is admin (use securityId - primary key)
      const isAdmin = await authService.isAdmin(req.securityId);
      if (!isAdmin) {
        return errorResponse(res, 'Admin access required', 403);
      }

      const { username, password, userId, role } = req.body;

      if (!username || !password) {
        return errorResponse(res, 'Username and password are required', 400);
      }

      const user = await authService.createUser({ username, password, userId, role });
      logger.info(`User created by admin: ${username}`);
      return successResponse(res, user, 'User created successfully', 201);
    } catch (error) {
      logger.error(`Create user error: ${error.message}`);
      return errorResponse(res, error.message, 400);
    }
  }

  // Update user (admin only)
  async updateUser(req, res) {
    try {
      // Check if requesting user is admin (use securityId - primary key)
      const isAdmin = await authService.isAdmin(req.securityId);
      if (!isAdmin) {
        return errorResponse(res, 'Admin access required', 403);
      }

      const { id } = req.params;
      const user = await authService.updateUser(id, req.body);
      logger.info(`User updated by admin: ${id}`);
      return successResponse(res, user, 'User updated successfully');
    } catch (error) {
      logger.error(`Update user error: ${error.message}`);
      return errorResponse(res, error.message, 400);
    }
  }

  // Delete user (admin only)
  async deleteUser(req, res) {
    try {
      // Check if requesting user is admin (use securityId - primary key)
      const isAdmin = await authService.isAdmin(req.securityId);
      if (!isAdmin) {
        return errorResponse(res, 'Admin access required', 403);
      }

      const { id } = req.params;

      // Prevent self-deletion (compare with securityId)
      if (parseInt(id) === parseInt(req.securityId)) {
        return errorResponse(res, 'Cannot delete your own account', 400);
      }

      const result = await authService.deleteUser(id);
      logger.info(`User deleted by admin: ${id}`);
      return successResponse(res, result, 'User deleted successfully');
    } catch (error) {
      logger.error(`Delete user error: ${error.message}`);
      return errorResponse(res, error.message, 400);
    }
  }
}

module.exports = new AuthController();
