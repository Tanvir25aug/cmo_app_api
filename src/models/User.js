const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

// ASP.NET Identity User Model
const User = sequelize.define('User', {
  Id: {
    type: DataTypes.STRING(450),
    primaryKey: true,
    allowNull: false
  },
  UserName: {
    type: DataTypes.STRING(256),
    allowNull: true
  },
  NormalizedUserName: {
    type: DataTypes.STRING(256),
    allowNull: true
  },
  Email: {
    type: DataTypes.STRING(256),
    allowNull: true
  },
  NormalizedEmail: {
    type: DataTypes.STRING(256),
    allowNull: true
  },
  EmailConfirmed: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false
  },
  PasswordHash: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  SecurityStamp: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  ConcurrencyStamp: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  PhoneNumber: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  PhoneNumberConfirmed: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false
  },
  TwoFactorEnabled: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false
  },
  LockoutEnd: {
    type: DataTypes.DATE,
    allowNull: true
  },
  LockoutEnabled: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false
  },
  AccessFailedCount: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0
  },
  // Custom fields
  FirstName: {
    type: DataTypes.STRING(100),
    allowNull: true
  },
  LastName: {
    type: DataTypes.STRING(100),
    allowNull: true
  },
  ProfilePicUrl: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  DateCreated: {
    type: DataTypes.DATE,
    allowNull: true
  },
  LastLoginTime: {
    type: DataTypes.DATE,
    allowNull: true
  },
  Activated: {
    type: DataTypes.BOOLEAN,
    allowNull: true,
    defaultValue: true
  },
  RoleId: {
    type: DataTypes.STRING(450),
    allowNull: true
  },
  UserId: {
    type: DataTypes.STRING(450),
    allowNull: true
  },
  MenuSecurityType: {
    type: DataTypes.STRING(50),
    allowNull: true
  }
}, {
  tableName: 'AspNetUsers',
  timestamps: false, // ASP.NET Identity doesn't use standard timestamps
  freezeTableName: true
});

// Instance method to verify password (ASP.NET Identity compatible)
User.prototype.comparePassword = async function(candidatePassword) {
  if (!this.PasswordHash) {
    return false;
  }

  // We'll use aspnet-identity-pw package for ASP.NET password verification
  const aspnetIdentity = require('aspnet-identity-pw');

  try {
    const result = await aspnetIdentity.validatePassword(candidatePassword, this.PasswordHash);
    return result;
  } catch (error) {
    console.error('Password verification error:', error);
    return false;
  }
};

// Custom toJSON to exclude sensitive data
User.prototype.toJSON = function() {
  const values = { ...this.get() };
  delete values.PasswordHash;
  delete values.SecurityStamp;
  delete values.ConcurrencyStamp;

  // Return simplified user object
  return {
    id: values.Id,
    username: values.UserName,
    email: values.Email,
    firstName: values.FirstName,
    lastName: values.LastName,
    fullName: values.FirstName && values.LastName ? `${values.FirstName} ${values.LastName}` : values.UserName,
    phone: values.PhoneNumber,
    profileImage: values.ProfilePicUrl,
    isActive: values.Activated,
    roleId: values.RoleId,
    lastLogin: values.LastLoginTime,
    emailConfirmed: values.EmailConfirmed
  };
};

module.exports = User;
