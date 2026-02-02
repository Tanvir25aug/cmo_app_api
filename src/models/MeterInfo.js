const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const MeterInfo = sequelize.define('MeterInfo', {
  Id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  CustomerId: {
    type: DataTypes.STRING(50)
  },
  OldConsumerId: {
    type: DataTypes.STRING(50)
  },
  InstallDate: {
    type: DataTypes.STRING(50)
  },
  Latitude: {
    type: DataTypes.DECIMAL(18, 10)
  },
  Longitude: {
    type: DataTypes.DECIMAL(18, 10)
  },
  HasOldMeterNo: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  OldMeterNoImgUrl: {
    type: DataTypes.STRING(500)
  },
  OldMeterNoOCR: {
    type: DataTypes.STRING(100)
  },
  OldMeterNoOld: {
    type: DataTypes.STRING(100)
  },
  HasOldMeterReading: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  OldMeterReadingImgUrl: {
    type: DataTypes.STRING(500)
  },
  OldMeterReadingOCR: {
    type: DataTypes.STRING(100)
  },
  OldMeterReadingOld: {
    type: DataTypes.STRING(100)
  },
  OldMeterPeak: {
    type: DataTypes.STRING(50)
  },
  OldMeterOffPeak: {
    type: DataTypes.STRING(50)
  },
  OldMeterKVAR: {
    type: DataTypes.STRING(50)
  },
  HasNewMeterNo: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  NewMeterNoImgUrl: {
    type: DataTypes.STRING(500)
  },
  NewMeterNoOCR: {
    type: DataTypes.STRING(100)
  },
  NewMeterNoOld: {
    type: DataTypes.STRING(100)
  },
  IsNewMeterDuplicate: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  NewMeterType: {
    type: DataTypes.STRING(20)
  },
  NewMeterBillingType: {
    type: DataTypes.STRING(50)
  },
  NewMeterConnectionType: {
    type: DataTypes.STRING(50)
  },
  IsPVCWireInstall: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  PVCWireSpec: {
    type: DataTypes.STRING(50)
  },
  PVCWireLength: {
    type: DataTypes.STRING(50)
  },
  HasBatteryCoverSeal: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  BatteryCoverSealImgUrl: {
    type: DataTypes.STRING(500)
  },
  BatteryCoverSealOCR: {
    type: DataTypes.STRING(100)
  },
  BatteryCoverSealOld: {
    type: DataTypes.STRING(100)
  },
  HasTerminalCoverSeal1: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  TerminalCoverSealImgUrl1: {
    type: DataTypes.STRING(500)
  },
  TerminalCoverSealOCR1: {
    type: DataTypes.STRING(100)
  },
  TerminalCoverSealOld1: {
    type: DataTypes.STRING(100)
  },
  HasTerminalCoverSeal2: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  TerminalCoverSealImgUrl2: {
    type: DataTypes.STRING(500)
  },
  TerminalCoverSealOCR2: {
    type: DataTypes.STRING(100)
  },
  TerminalCoverSealOld2: {
    type: DataTypes.STRING(100)
  },
  HasSteelBox: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  IsSteelBoxRemove: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  SteelBoxRemoveUrl: {
    type: DataTypes.STRING(500)
  },
  MeterInstalledBy: {
    type: DataTypes.STRING(100)
  },
  HasRevisit: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  RevisitDt: {
    type: DataTypes.STRING(50)
  },
  RectifyStatus: {
    type: DataTypes.STRING(50)
  },
  RectifyMessage: {
    type: DataTypes.STRING(500)
  },
  IsApproved: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  ApprovedBy: {
    type: DataTypes.INTEGER
  },
  ApprovedDate: {
    type: DataTypes.STRING(50)
  },
  IsMDMEntry: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  IsAppsEntry: {
    type: DataTypes.INTEGER,
    defaultValue: 1
  },
  IsActive: {
    type: DataTypes.INTEGER,
    defaultValue: 1
  },
  CreateBy: {
    type: DataTypes.INTEGER
  },
  CreateDate: {
    type: DataTypes.STRING(50)
  },
  UpdateBy: {
    type: DataTypes.INTEGER
  },
  UpdateDate: {
    type: DataTypes.STRING(50)
  }
}, {
  tableName: 'MeterInfo_test',
  timestamps: false,
  freezeTableName: true
});

module.exports = MeterInfo;
