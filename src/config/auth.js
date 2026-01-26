require('dotenv').config();

module.exports = {
  jwtSecret: process.env.JWT_SECRET || 'default-secret-change-in-production',
  jwtExpire: process.env.JWT_EXPIRE || '24h',
  jwtRefreshExpire: process.env.JWT_REFRESH_EXPIRE || '7d',
  saltRounds: 10
};
