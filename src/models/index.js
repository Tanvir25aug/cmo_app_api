const { sequelize } = require('../config/database');
const User = require('./User');
const AdminSecurity = require('./AdminSecurity');
const CMO = require('./CMO');

// Define associations with AdminSecurity (primary authentication table)
AdminSecurity.hasMany(CMO, {
  foreignKey: 'userId',
  sourceKey: 'UserId',
  as: 'cmos'
});

CMO.belongsTo(AdminSecurity, {
  foreignKey: 'userId',
  targetKey: 'UserId',
  as: 'user'
});

// Sync database (create tables if not exist)
const syncDatabase = async (force = false) => {
  try {
    await sequelize.sync({ force, alter: !force });
    console.log('✅ Database synchronized successfully.');

    if (force) {
      console.log('⚠️  Database tables recreated (all data lost)');
    }
  } catch (error) {
    console.error('❌ Database sync error:', error.message);
    throw error;
  }
};

module.exports = {
  sequelize,
  User,
  AdminSecurity,
  CMO,
  syncDatabase
};
