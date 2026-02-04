const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const AppVersion = sequelize.define('AppVersion', {
  Id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  VersionCode: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  VersionName: {
    type: DataTypes.STRING(50),
    allowNull: false
  },
  FileName: {
    type: DataTypes.STRING(255),
    allowNull: false
  },
  FilePath: {
    type: DataTypes.STRING(500),
    allowNull: false
  },
  FileSize: {
    type: DataTypes.BIGINT
  },
  ReleaseNotes: {
    type: DataTypes.TEXT
  },
  IsMandatory: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  IsActive: {
    type: DataTypes.INTEGER,
    defaultValue: 1
  },
  DownloadCount: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  UploadedBy: {
    type: DataTypes.INTEGER
  },
  CreatedAt: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  UpdatedAt: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  }
}, {
  tableName: 'AppVersions',
  timestamps: false,
  freezeTableName: true
});

module.exports = AppVersion;
