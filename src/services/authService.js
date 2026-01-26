const jwt = require('jsonwebtoken');
const { Op } = require('sequelize');
const { AdminSecurity } = require('../models');
const { jwtSecret, jwtExpire, jwtRefreshExpire } = require('../config/auth');

class AuthService {
  // Generate JWT token
  generateToken(user, expiresIn = jwtExpire) {
    const userJson = user.toJSON();
    return jwt.sign(
      {
        id: userJson.id,
        userId: userJson.userId,
        username: userJson.username
      },
      jwtSecret,
      { expiresIn }
    );
  }

  // Login user with AdminSecurity table (plain text password)
  async login(username, password) {
    // Find user by username
    const user = await AdminSecurity.findOne({
      where: {
        UserName: username
      }
    });

    if (!user) {
      throw new Error('Invalid credentials');
    }

    // Check password using plain text comparison
    const isMatch = user.comparePassword(password);

    if (!isMatch) {
      throw new Error('Invalid credentials');
    }

    // Generate tokens
    const accessToken = this.generateToken(user);
    const refreshToken = this.generateToken(user, jwtRefreshExpire);

    return {
      user: user.toJSON(),
      accessToken,
      refreshToken
    };
  }

  // Refresh token
  async refreshToken(refreshToken) {
    try {
      const decoded = jwt.verify(refreshToken, jwtSecret);
      const user = await AdminSecurity.findByPk(decoded.id);

      if (!user) {
        throw new Error('Invalid refresh token');
      }

      const newAccessToken = this.generateToken(user);

      return {
        accessToken: newAccessToken
      };
    } catch (error) {
      throw new Error('Invalid or expired refresh token');
    }
  }

  // Get user profile
  async getProfile(userId) {
    const user = await AdminSecurity.findByPk(userId);

    if (!user) {
      throw new Error('User not found');
    }

    return user.toJSON();
  }

  // Update user profile (limited fields only)
  async updateProfile(userId, updates) {
    const user = await AdminSecurity.findByPk(userId);

    if (!user) {
      throw new Error('User not found');
    }

    // Only allow updating UserName field
    const allowedFields = ['UserName'];
    const filteredUpdates = {};

    Object.keys(updates).forEach(key => {
      if (allowedFields.includes(key)) {
        filteredUpdates[key] = updates[key];
      }
    });

    if (Object.keys(filteredUpdates).length > 0) {
      await user.update(filteredUpdates);
    }

    return user.toJSON();
  }
}

module.exports = new AuthService();
