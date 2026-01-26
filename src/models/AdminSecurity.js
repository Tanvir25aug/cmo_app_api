const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

// AdminSecurity Model for authentication
const AdminSecurity = sequelize.define('AdminSecurity', {
  SecurityId: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false
  },
  UserId: {
    type: DataTypes.STRING(50),
    allowNull: true
  },
  UserName: {
    type: DataTypes.STRING(100),
    allowNull: true
  },
  UserPwd: {
    type: DataTypes.STRING(100),
    allowNull: true
  }
}, {
  tableName: 'AdminSecurity',
  timestamps: false,
  freezeTableName: true
});

// Instance method to verify password (plain text comparison)
AdminSecurity.prototype.comparePassword = function(candidatePassword) {
  // Simple plain text comparison
  return this.UserPwd === candidatePassword;
};

// Custom toJSON to exclude sensitive data
AdminSecurity.prototype.toJSON = function() {
  const values = { ...this.get() };
  delete values.UserPwd;

  // Return simplified user object
  return {
    id: values.SecurityId,
    userId: values.UserId,
    username: values.UserName
  };
};

module.exports = AdminSecurity;
