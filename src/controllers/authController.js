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
}

module.exports = new AuthController();
