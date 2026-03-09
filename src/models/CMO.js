const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const CMO = sequelize.define('CMO', {
  id: {
    type: DataTypes.CHAR(36),
    primaryKey: true,
    defaultValue: DataTypes.UUIDV4
  },

  // Customer Information
  customerId: {
    type: DataTypes.STRING(50),
    field: 'customer_id'
  },
  newMeterId: {
    type: DataTypes.STRING(50),
    field: 'new_meter_id'
  },
  customerName: {
    type: DataTypes.STRING(100),
    allowNull: false,
    field: 'customer_name'
  },
  flatNo: {
    type: DataTypes.STRING(20),
    field: 'flat_no'
  },
  floor: {
    type: DataTypes.STRING(20)
  },
  mobileNumber: {
    type: DataTypes.STRING(20),
    allowNull: false,
    field: 'mobile_number'
  },
  secondaryMobileNumber: {
    type: DataTypes.STRING(20),
    field: 'secondary_mobile_number'
  },
  email: {
    type: DataTypes.STRING(100),
    validate: {
      isEmail: true
    }
  },
  nid: {
    type: DataTypes.STRING(20)
  },
  nocs: {
    type: DataTypes.STRING(50)
  },

  // Meter Details
  feeder: {
    type: DataTypes.STRING(50)
  },
  billGroup: {
    type: DataTypes.STRING(50),
    field: 'bill_group'
  },
  sanctionLoad: {
    type: DataTypes.STRING(20),
    field: 'sanction_load'
  },
  bookNumber: {
    type: DataTypes.STRING(50),
    field: 'book_number'
  },
  tariff: {
    type: DataTypes.STRING(50)
  },

  // Old Meter Information
  oldMeterType: {
    type: DataTypes.STRING(10),
    field: 'old_meter_type',
    validate: {
      isIn: [['1P', '3P']]
    }
  },
  oldMeterNumber: {
    type: DataTypes.STRING(50),
    field: 'old_meter_number'
  },
  oldMeterImagePath: {
    type: DataTypes.STRING(255),
    field: 'old_meter_image_path'
  },
  oldMeterReading: {
    type: DataTypes.STRING(20),
    field: 'old_meter_reading'
  },
  onPeak: {
    type: DataTypes.STRING(20),
    field: 'on_peak'
  },
  offPeak: {
    type: DataTypes.STRING(20),
    field: 'off_peak'
  },
  kvar: {
    type: DataTypes.STRING(20)
  },

  // Installation Information
  installDate: {
    type: DataTypes.DATEONLY,
    field: 'install_date'
  },

  // Seal Information
  batteryCoverSeal: {
    type: DataTypes.STRING(50),
    field: 'battery_cover_seal'
  },
  batteryCoverSealImagePath: {
    type: DataTypes.STRING(255),
    field: 'battery_cover_seal_image_path'
  },
  terminalSeal1: {
    type: DataTypes.STRING(50),
    field: 'terminal_seal_1'
  },
  terminalSeal2: {
    type: DataTypes.STRING(50),
    field: 'terminal_seal_2'
  },
  terminalCoverSealImagePath: {
    type: DataTypes.STRING(255),
    field: 'terminal_cover_seal_image_path'
  },

  // Additional Information
  hasSteelBox: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
    field: 'has_steel_box'
  },
  installBy: {
    type: DataTypes.STRING(100),
    field: 'install_by'
  },

  // Status & Sync
  status: {
    type: DataTypes.STRING(20),
    defaultValue: 'draft',
    validate: {
      isIn: [['draft', 'pending', 'uploaded', 'approved', 'rejected']]
    }
  },
  isSynced: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
    field: 'is_synced'
  },
  syncedAt: {
    type: DataTypes.DATE,
    field: 'synced_at'
  },

  // User Reference (references AdminSecurity.UserId)
  userId: {
    type: DataTypes.STRING(450),
    allowNull: false,
    field: 'user_id',
    references: {
      model: 'AdminSecurity',
      key: 'UserId'
    }
  }
}, {
  tableName: 'cmo_requests',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  freezeTableName: true
});

module.exports = CMO;
