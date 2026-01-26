// =============================================
// Create Test User by Copying Existing Password
// =============================================
require('dotenv').config();
const { sequelize } = require('./src/config/database');
const { v4: uuidv4 } = require('uuid');

async function createTestUser() {
  try {
    console.log('\n========================================');
    console.log('Creating Test User');
    console.log('========================================\n');

    // Test database connection
    await sequelize.authenticate();
    console.log('✅ Database connected\n');

    // STEP 1: Get password hash from existing user
    const sourceEmail = 'abid.oculin2022@gmail.com';

    const [existingUsers] = await sequelize.query(`
      SELECT Email, PasswordHash, FirstName, LastName
      FROM AspNetUsers
      WHERE Email = :email
    `, {
      replacements: { email: sourceEmail },
      type: sequelize.QueryTypes.SELECT
    });

    if (!existingUsers) {
      console.log('❌ Source user not found:', sourceEmail);
      console.log('\nAvailable users:');

      const [allUsers] = await sequelize.query(`
        SELECT Email, FirstName, LastName
        FROM AspNetUsers
      `);

      allUsers.forEach(user => {
        console.log(`  - ${user.Email} (${user.FirstName} ${user.LastName})`);
      });

      process.exit(1);
    }

    console.log(`✅ Found source user: ${sourceEmail}\n`);

    // STEP 2: Check if test user already exists
    const [checkUser] = await sequelize.query(`
      SELECT Email FROM AspNetUsers WHERE Email = 'testuser@otbl.com'
    `, {
      type: sequelize.QueryTypes.SELECT
    });

    if (checkUser) {
      console.log('⚠️  User testuser@otbl.com already exists!\n');
      console.log('You can use this user to login:');
      console.log('  Email:    testuser@otbl.com');
      console.log('  Password: [Same as ' + sourceEmail + ']\n');
      process.exit(0);
    }

    // STEP 3: Create new user with same password
    const newUserId = uuidv4();
    const securityStamp = uuidv4();
    const concurrencyStamp = uuidv4();

    await sequelize.query(`
      INSERT INTO AspNetUsers (
        Id, UserName, NormalizedUserName, Email, NormalizedEmail,
        EmailConfirmed, PasswordHash, SecurityStamp, ConcurrencyStamp,
        PhoneNumber, PhoneNumberConfirmed, TwoFactorEnabled,
        LockoutEnabled, AccessFailedCount, FirstName, LastName,
        DateCreated, Activated
      )
      VALUES (
        :id, :username, :normalizedUserName, :email, :normalizedEmail,
        1, :passwordHash, :securityStamp, :concurrencyStamp,
        :phone, 1, 0, 0, 0, :firstName, :lastName,
        GETDATE(), 1
      )
    `, {
      replacements: {
        id: newUserId,
        username: 'testuser',
        normalizedUserName: 'TESTUSER',
        email: 'testuser@otbl.com',
        normalizedEmail: 'TESTUSER@OTBL.COM',
        passwordHash: existingUsers.PasswordHash,
        securityStamp,
        concurrencyStamp,
        phone: '01712345678',
        firstName: 'Test',
        lastName: 'User'
      },
      type: sequelize.QueryTypes.INSERT
    });

    console.log('========================================');
    console.log('✅ Test User Created Successfully!');
    console.log('========================================\n');
    console.log('Login Credentials:');
    console.log('  Email:    testuser@otbl.com');
    console.log('  Password: Abid@123');
    console.log('');
    console.log('User Details:');
    console.log('  Name:     Test User');
    console.log('  Phone:    01712345678');
    console.log('  Active:   Yes');
    console.log('');
    console.log('(Password copied from ' + sourceEmail + ')');
    console.log('');

    process.exit(0);
  } catch (error) {
    console.error('\n❌ Error creating test user:', error.message);

    if (error.message.includes('INSERT permission')) {
      console.log('\n⚠️  Permission denied. Please run this SQL in SSMS:');
      console.log('\nGRANT INSERT ON AspNetUsers TO rdpdc;');
      console.log('GO\n');
    }

    process.exit(1);
  }
}

createTestUser();
