// =============================================
// Create Test User via Direct Database Insert
// =============================================
require('dotenv').config();
const { sequelize } = require('./src/config/database');
const sql = require('mssql');
const bcrypt = require('bcryptjs');

async function createTestUser() {
  try {
    console.log('\n========================================');
    console.log('Creating Test User');
    console.log('========================================\n');

    // Test database connection
    await sequelize.authenticate();
    console.log('✅ Database connected\n');

    // User details
    const email = 'testuser@otbl.com';
    const password = 'Admin@123';
    const username = 'testuser';
    const firstName = 'Test';
    const lastName = 'User';
    const phone = '01712345678';

    // Hash password using bcrypt (ASP.NET Identity compatible format)
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    console.log('Password hashed successfully\n');

    // Delete existing user if exists
    await sequelize.query(`
      DELETE FROM AspNetUsers WHERE Email = :email
    `, {
      replacements: { email },
      type: sequelize.QueryTypes.DELETE
    });

    console.log('Cleared existing user (if any)\n');

    // Insert new user
    const userId = require('uuid').v4();
    const securityStamp = require('uuid').v4();
    const concurrencyStamp = require('uuid').v4();

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
        id: userId,
        username,
        normalizedUserName: username.toUpperCase(),
        email,
        normalizedEmail: email.toUpperCase(),
        passwordHash,
        securityStamp,
        concurrencyStamp,
        phone,
        firstName,
        lastName
      },
      type: sequelize.QueryTypes.INSERT
    });

    console.log('========================================');
    console.log('✅ Test User Created Successfully!');
    console.log('========================================\n');
    console.log('Login Credentials:');
    console.log(`  Email:    ${email}`);
    console.log(`  Password: ${password}`);
    console.log('');
    console.log('User Details:');
    console.log(`  Name:     ${firstName} ${lastName}`);
    console.log(`  Phone:    ${phone}`);
    console.log(`  Active:   Yes`);
    console.log('');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error creating test user:', error);
    process.exit(1);
  }
}

createTestUser();
