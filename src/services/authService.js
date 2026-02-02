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

    // Update last login time
    await user.update({ lastLogin: new Date() });

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

  // ============ Admin User Management ============

  // Get all users (admin only)
  async getAllUsers() {
    const users = await AdminSecurity.findAll({
      order: [['SecurityId', 'DESC']]
    });
    return users.map(user => user.toJSON());
  }

  // Create new user (admin only)
  async createUser(userData) {
    const { username, password, userId, role } = userData;

    // Check if username already exists
    const existingUser = await AdminSecurity.findOne({
      where: { UserName: username }
    });

    if (existingUser) {
      throw new Error('Username already exists');
    }

    // Create new user
    const newUser = await AdminSecurity.create({
      UserId: userId || username,
      UserName: username,
      UserPwd: password, // Plain text as per existing system
      Rrole: role || 'user',
      lastLogin: null
    });

    return newUser.toJSON();
  }

  // Update user (admin only)
  async updateUser(securityId, updates) {
    const user = await AdminSecurity.findByPk(securityId);

    if (!user) {
      throw new Error('User not found');
    }

    const allowedFields = ['UserName', 'UserId', 'Rrole', 'UserPwd'];
    const filteredUpdates = {};

    Object.keys(updates).forEach(key => {
      if (allowedFields.includes(key)) {
        filteredUpdates[key] = updates[key];
      }
    });

    // Handle role field mapping
    if (updates.role !== undefined) {
      filteredUpdates.Rrole = updates.role;
    }

    if (Object.keys(filteredUpdates).length > 0) {
      await user.update(filteredUpdates);
    }

    return user.toJSON();
  }

  // Delete user (admin only)
  async deleteUser(securityId) {
    const user = await AdminSecurity.findByPk(securityId);

    if (!user) {
      throw new Error('User not found');
    }

    await user.destroy();
    return { message: 'User deleted successfully' };
  }

  // Check if user is admin
  async isAdmin(securityId) {
    const user = await AdminSecurity.findByPk(securityId);
    if (!user) return false;
    return user.Rrole && user.Rrole.toLowerCase() === 'admin';
  }
}

module.exports = new AuthService();
