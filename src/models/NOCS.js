const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

// NOCS (Substation) Model
const NOCS = sequelize.define('NOCS', {
  ID: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false
  },
  NOCS_NAME: {
    type: DataTypes.STRING(100),
    allowNull: true
  },
  LAT: {
    type: DataTypes.DECIMAL(10, 8),
    allowNull: true
  },
  LONG: {
    type: DataTypes.DECIMAL(11, 8),
    allowNull: true
  }
}, {
  tableName: 'NOCS_LAT_LONG',
  timestamps: false,
  freezeTableName: true
});

// Custom toJSON
NOCS.prototype.toJSON = function() {
  const values = { ...this.get() };
  return {
    id: values.ID,
    name: values.NOCS_NAME,
    latitude: values.LAT ? parseFloat(values.LAT) : null,
    longitude: values.LONG ? parseFloat(values.LONG) : null
  };
};

module.exports = NOCS;
