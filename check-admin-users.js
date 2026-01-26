require('dotenv').config();
const { sequelize } = require('./src/config/database');
const AdminSecurity = require('./src/models/AdminSecurity');

async function checkUsers() {
  try {
    await sequelize.authenticate();
    console.log('✅ Database connected\n');

    const users = await AdminSecurity.findAll();

    console.log(`Found ${users.length} users in AdminSecurity table:\n`);

    users.forEach(user => {
      console.log('--------------------------------');
      console.log(`SecurityId: ${user.SecurityId}`);
      console.log(`UserId: ${user.UserId}`);
      console.log(`UserName: ${user.UserName}`);
      console.log(`Password: ${user.UserPwd}`);
      console.log('--------------------------------\n');
    });

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

checkUsers();
