const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

// DCU (Data Concentrator Unit) Model
const DCU = sequelize.define('DCU', {
  ID: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false
  },
  DCU_ID: {
    type: DataTypes.STRING(50),
    allowNull: true
  },
  DCU_ADD: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  LAT: {
    type: DataTypes.DECIMAL(10, 8),
    allowNull: true
  },
  LONG: {
    type: DataTypes.DECIMAL(11, 8),
    allowNull: true
  },
  NOCS: {
    type: DataTypes.STRING(100),
    allowNull: true
  }
}, {
  tableName: 'DCU_LAT_LONG',
  timestamps: false,
  freezeTableName: true
});

// Custom toJSON
DCU.prototype.toJSON = function() {
  const values = { ...this.get() };
  return {
    id: values.ID,
    dcuId: values.DCU_ID,
    address: values.DCU_ADD,
    latitude: values.LAT ? parseFloat(values.LAT) : null,
    longitude: values.LONG ? parseFloat(values.LONG) : null,
    nocs: values.NOCS
  };
};

module.exports = DCU;
