import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart';
import '../models/meter_reading_model.dart';
import '../models/cmo_model.dart';
import '../models/customer_model.dart';
import '../models/bulk_cmo_group_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('meter_ocr.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web platform is not supported for this app. Please use Android or iOS.',
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        fullName TEXT,
        phone TEXT,
        role TEXT,
        profileImage TEXT,
        createdAt TEXT,
        lastLogin TEXT,
        password TEXT NOT NULL
      )
    ''');

    // Meter readings table
    await db.execute('''
      CREATE TABLE meter_readings (
        id TEXT PRIMARY KEY,
        meterNumber TEXT NOT NULL,
        reading TEXT NOT NULL,
        previousReading TEXT,
        consumerName TEXT,
        consumerAddress TEXT,
        meterType TEXT,
        imagePath TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        readingDate TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0,
        remarks TEXT,
        userId TEXT,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Create index for better query performance
    await db.execute('''
      CREATE INDEX idx_meter_number ON meter_readings(meterNumber)
    ''');

    await db.execute('''
      CREATE INDEX idx_reading_date ON meter_readings(readingDate)
    ''');

    // CMO table
    await db.execute('''
      CREATE TABLE cmo_requests (
        id TEXT PRIMARY KEY,
        customer_id TEXT,
        new_meter_id TEXT,
        customer_name TEXT NOT NULL,
        flat_no TEXT,
        floor TEXT,
        mobile_number TEXT NOT NULL,
        secondary_mobile_number TEXT,
        email TEXT,
        nid TEXT,
        nocs TEXT,
        feeder TEXT,
        bill_group TEXT,
        sanction_load TEXT,
        book_number TEXT,
        tariff TEXT,
        old_meter_type TEXT,
        old_meter_category TEXT,
        old_meter_number TEXT,
        old_meter_image_path TEXT,
        old_meter_reading TEXT,
        on_peak TEXT,
        off_peak TEXT,
        kvar TEXT,
        new_meter_image_path TEXT,
        new_meter_latitude REAL,
        new_meter_longitude REAL,
        install_date TEXT,
        battery_cover_seal TEXT,
        battery_cover_seal_image_path TEXT,
        terminal_seal_1 TEXT,
        terminal_seal_2 TEXT,
        terminal_cover_seal_image_path TEXT,
        has_steel_box INTEGER DEFAULT 0,
        install_by TEXT,
        status TEXT DEFAULT 'draft',
        is_synced INTEGER NOT NULL DEFAULT 0,
        synced_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        user_id TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Create index for CMO queries
    await db.execute('''
      CREATE INDEX idx_cmo_status ON cmo_requests(status)
    ''');

    await db.execute('''
      CREATE INDEX idx_cmo_created_at ON cmo_requests(created_at)
    ''');

    // Customers table for offline support
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        index_no TEXT,
        old_consumer_id TEXT UNIQUE,
        customer_name TEXT,
        address TEXT,
        floor_no TEXT,
        flat_no TEXT,
        passport TEXT,
        birth_certificate TEXT,
        nid TEXT,
        mobile_no TEXT,
        changed_mobile_no TEXT,
        secondary_mobile_no TEXT,
        email_id TEXT,
        father_name TEXT,
        mother_name TEXT,
        spouse_name TEXT,
        dob TEXT,
        mailing_country TEXT,
        mailing_postal_code TEXT,
        mailing_district TEXT,
        premise_type TEXT,
        country TEXT,
        postal_code TEXT,
        district TEXT,
        thana TEXT,
        area TEXT,
        zone TEXT,
        zone_code TEXT,
        circle TEXT,
        circle_code TEXT,
        nocs TEXT,
        nocs_code TEXT,
        sector TEXT,
        customer_created_dt TEXT,
        bill_route_type TEXT,
        relationship_type TEXT,
        bill_group TEXT,
        old_new_customer TEXT,
        vip_customer TEXT,
        connection_type TEXT,
        old_account_no TEXT,
        meter_owner TEXT,
        meter_type TEXT,
        meter_type_remarks TEXT,
        transformer_owner TEXT,
        transformer_side TEXT,
        cpc_cpr TEXT,
        cpr_consumer_id TEXT,
        likely_consumption TEXT,
        walk_order TEXT,
        book TEXT,
        netmeter_flag TEXT,
        xformer_cd TEXT,
        metering_mode TEXT,
        omf TEXT,
        cust_tariff_category TEXT,
        sanctioned_load TEXT,
        connected_load TEXT,
        business_type TEXT,
        business_type_desc TEXT,
        no_of_spm_cust TEXT,
        vat_rebate TEXT,
        special_category TEXT,
        status_code TEXT,
        ministry TEXT,
        organization TEXT,
        dmd_charge_aft_migr TEXT,
        sub_station_cd TEXT,
        sub_station_name TEXT,
        feeder_cd TEXT,
        feeder_name TEXT,
        synced_at TEXT
      )
    ''');

    // Create index for customer queries
    await db.execute('''
      CREATE INDEX idx_customer_old_consumer_id ON customers(old_consumer_id)
    ''');

    // Bulk CMO groups table
    await db.execute('''
      CREATE TABLE bulk_cmo_groups (
        id TEXT PRIMARY KEY,
        building_name TEXT,
        building_address TEXT,
        latitude REAL,
        longitude REAL,
        feeder TEXT,
        install_by TEXT,
        meter_count INTEGER DEFAULT 0,
        completed_count INTEGER DEFAULT 0,
        status TEXT DEFAULT 'draft',
        created_at TEXT NOT NULL,
        updated_at TEXT,
        user_id INTEGER
      )
    ''');

    // Bulk meter entries table
    await db.execute('''
      CREATE TABLE bulk_meter_entries (
        id TEXT PRIMARY KEY,
        bulk_group_id TEXT NOT NULL,
        meter_index INTEGER NOT NULL,
        customer_id TEXT,
        customer_name TEXT,
        flat_no TEXT,
        floor TEXT,
        tracking_number TEXT,
        new_meter_id TEXT,
        mobile_number TEXT,
        is_complete INTEGER DEFAULT 0,
        cmo_id TEXT,
        FOREIGN KEY (bulk_group_id) REFERENCES bulk_cmo_groups (id),
        FOREIGN KEY (cmo_id) REFERENCES cmo_requests (id)
      )
    ''');

    // Add bulk_group_id column to cmo_requests
    await db.execute('''
      ALTER TABLE cmo_requests ADD COLUMN bulk_group_id TEXT
    ''');

    await db.execute('''
      ALTER TABLE cmo_requests ADD COLUMN meter_index INTEGER
    ''');

    // Create indexes for bulk CMO queries
    await db.execute('''
      CREATE INDEX idx_bulk_group_status ON bulk_cmo_groups(status)
    ''');

    await db.execute('''
      CREATE INDEX idx_bulk_entry_group ON bulk_meter_entries(bulk_group_id)
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add CMO table for version 2
      await db.execute('''
        CREATE TABLE cmo_requests (
          id TEXT PRIMARY KEY,
          customer_id TEXT,
          new_meter_id TEXT,
          customer_name TEXT NOT NULL,
          flat_no TEXT,
          floor TEXT,
          mobile_number TEXT NOT NULL,
          secondary_mobile_number TEXT,
          email TEXT,
          nid TEXT,
          nocs TEXT,
          feeder TEXT,
          bill_group TEXT,
          sanction_load TEXT,
          book_number TEXT,
          tariff TEXT,
          old_meter_type TEXT,
          old_meter_number TEXT,
          old_meter_image_path TEXT,
          old_meter_reading TEXT,
          on_peak TEXT,
          off_peak TEXT,
          kvar TEXT,
          install_date TEXT,
          battery_cover_seal TEXT,
          battery_cover_seal_image_path TEXT,
          terminal_seal_1 TEXT,
          terminal_seal_2 TEXT,
          terminal_cover_seal_image_path TEXT,
          has_steel_box INTEGER DEFAULT 0,
          install_by TEXT,
          status TEXT DEFAULT 'draft',
          is_synced INTEGER NOT NULL DEFAULT 0,
          synced_at TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          user_id TEXT,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_cmo_status ON cmo_requests(status)
      ''');

      await db.execute('''
        CREATE INDEX idx_cmo_created_at ON cmo_requests(created_at)
      ''');
    }

    if (oldVersion < 3) {
      // Add install_date column for version 3
      try {
        await db.execute('''
          ALTER TABLE cmo_requests ADD COLUMN install_date TEXT
        ''');
      } catch (e) {
        print('Error adding install_date column: $e');
      }
    }

    if (oldVersion < 4) {
      // Add sync columns for version 4
      try {
        await db.execute('''
          ALTER TABLE cmo_requests ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0
        ''');
      } catch (e) {
        print('Error adding is_synced column: $e');
      }

      try {
        await db.execute('''
          ALTER TABLE cmo_requests ADD COLUMN synced_at TEXT
        ''');
      } catch (e) {
        print('Error adding synced_at column: $e');
      }
    }

    if (oldVersion < 5) {
      // Add customers table for version 5
      try {
        await db.execute('''
          CREATE TABLE customers (
            id TEXT PRIMARY KEY,
            index_no TEXT,
            old_consumer_id TEXT UNIQUE,
            customer_name TEXT,
            address TEXT,
            floor_no TEXT,
            flat_no TEXT,
            passport TEXT,
            birth_certificate TEXT,
            nid TEXT,
            mobile_no TEXT,
            changed_mobile_no TEXT,
            secondary_mobile_no TEXT,
            email_id TEXT,
            father_name TEXT,
            mother_name TEXT,
            spouse_name TEXT,
            dob TEXT,
            mailing_country TEXT,
            mailing_postal_code TEXT,
            mailing_district TEXT,
            premise_type TEXT,
            country TEXT,
            postal_code TEXT,
            district TEXT,
            thana TEXT,
            area TEXT,
            zone TEXT,
            zone_code TEXT,
            circle TEXT,
            circle_code TEXT,
            nocs TEXT,
            nocs_code TEXT,
            sector TEXT,
            customer_created_dt TEXT,
            bill_route_type TEXT,
            relationship_type TEXT,
            bill_group TEXT,
            old_new_customer TEXT,
            vip_customer TEXT,
            connection_type TEXT,
            old_account_no TEXT,
            meter_owner TEXT,
            meter_type TEXT,
            meter_type_remarks TEXT,
            transformer_owner TEXT,
            transformer_side TEXT,
            cpc_cpr TEXT,
            cpr_consumer_id TEXT,
            likely_consumption TEXT,
            walk_order TEXT,
            book TEXT,
            netmeter_flag TEXT,
            xformer_cd TEXT,
            metering_mode TEXT,
            omf TEXT,
            cust_tariff_category TEXT,
            sanctioned_load TEXT,
            connected_load TEXT,
            business_type TEXT,
            business_type_desc TEXT,
            no_of_spm_cust TEXT,
            vat_rebate TEXT,
            special_category TEXT,
            status_code TEXT,
            ministry TEXT,
            organization TEXT,
            dmd_charge_aft_migr TEXT,
            sub_station_cd TEXT,
            sub_station_name TEXT,
            feeder_cd TEXT,
            feeder_name TEXT,
            synced_at TEXT
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_customer_old_consumer_id ON customers(old_consumer_id)
        ''');
      } catch (e) {
        print('Error creating customers table: $e');
      }
    }

    if (oldVersion < 6) {
      // Add new meter fields for version 6
      try {
        await db.execute('''
          ALTER TABLE cmo_requests ADD COLUMN old_meter_category TEXT
        ''');
      } catch (e) {
        print('Error adding old_meter_category column: $e');
      }

      try {
        await db.execute('''
          ALTER TABLE cmo_requests ADD COLUMN new_meter_image_path TEXT
        ''');
      } catch (e) {
        print('Error adding new_meter_image_path column: $e');
      }

      try {
        await db.execute('''
          ALTER TABLE cmo_requests ADD COLUMN new_meter_latitude REAL
        ''');
      } catch (e) {
        print('Error adding new_meter_latitude column: $e');
      }

      try {
        await db.execute('''
          ALTER TABLE cmo_requests ADD COLUMN new_meter_longitude REAL
        ''');
      } catch (e) {
        print('Error adding new_meter_longitude column: $e');
      }
    }

    if (oldVersion < 7) {
      // Add bulk CMO tables for version 7
      try {
        await db.execute('''
          CREATE TABLE bulk_cmo_groups (
            id TEXT PRIMARY KEY,
            building_name TEXT,
            building_address TEXT,
            latitude REAL,
            longitude REAL,
            feeder TEXT,
            install_by TEXT,
            meter_count INTEGER DEFAULT 0,
            completed_count INTEGER DEFAULT 0,
            status TEXT DEFAULT 'draft',
            created_at TEXT NOT NULL,
            updated_at TEXT,
            user_id INTEGER
          )
        ''');
      } catch (e) {
        print('Error creating bulk_cmo_groups table: $e');
      }

      try {
        await db.execute('''
          CREATE TABLE bulk_meter_entries (
            id TEXT PRIMARY KEY,
            bulk_group_id TEXT NOT NULL,
            meter_index INTEGER NOT NULL,
            customer_id TEXT,
            customer_name TEXT,
            flat_no TEXT,
            floor TEXT,
            tracking_number TEXT,
            new_meter_id TEXT,
            mobile_number TEXT,
            is_complete INTEGER DEFAULT 0,
            cmo_id TEXT
          )
        ''');
      } catch (e) {
        print('Error creating bulk_meter_entries table: $e');
      }

      try {
        await db.execute('''
          ALTER TABLE cmo_requests ADD COLUMN bulk_group_id TEXT
        ''');
      } catch (e) {
        print('Error adding bulk_group_id column: $e');
      }

      try {
        await db.execute('''
          ALTER TABLE cmo_requests ADD COLUMN meter_index INTEGER
        ''');
      } catch (e) {
        print('Error adding meter_index column: $e');
      }

      try {
        await db.execute('''
          CREATE INDEX idx_bulk_group_status ON bulk_cmo_groups(status)
        ''');
      } catch (e) {
        print('Error creating bulk group index: $e');
      }

      try {
        await db.execute('''
          CREATE INDEX idx_bulk_entry_group ON bulk_meter_entries(bulk_group_id)
        ''');
      } catch (e) {
        print('Error creating bulk entry index: $e');
      }
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // User operations
  Future<String?> createUser(User user, String password) async {
    final db = await database;
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final data = user.toMap();
      data['id'] = id;
      data['password'] = _hashPassword(password); // Hash the password
      data['createdAt'] = DateTime.now().toIso8601String();

      await db.insert('users', data);
      return id;
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }

  Future<User?> loginUser(String username, String password) async {
    final db = await database;
    try {
      final results = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );

      if (results.isNotEmpty) {
        final storedPassword = results.first['password'] as String;
        final hashedPassword = _hashPassword(password);

        if (storedPassword == hashedPassword) {
          // Update last login
          await db.update(
            'users',
            {'lastLogin': DateTime.now().toIso8601String()},
            where: 'id = ?',
            whereArgs: [results.first['id']],
          );
          return User.fromMap(results.first);
        }
      }
      return null;
    } catch (e) {
      print('Error logging in: $e');
      return null;
    }
  }

  Future<User?> getUserById(String id) async {
    final db = await database;
    try {
      final results = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (results.isNotEmpty) {
        return User.fromMap(results.first);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Get all users (for admin)
  Future<List<User>> getAllUsers() async {
    final db = await database;
    try {
      final results = await db.query(
        'users',
        orderBy: 'createdAt DESC',
      );
      return results.map((map) => User.fromMap(map)).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Create user by admin (with role assignment)
  Future<String?> createUserByAdmin(User user, String password, String role) async {
    final db = await database;
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final data = user.toMap();
      data['id'] = id;
      data['password'] = _hashPassword(password);
      data['role'] = role;
      data['createdAt'] = DateTime.now().toIso8601String();

      await db.insert('users', data);
      return id;
    } catch (e) {
      print('Error creating user by admin: $e');
      return null;
    }
  }

  // Update user role
  Future<bool> updateUserRole(String userId, String role) async {
    final db = await database;
    try {
      await db.update(
        'users',
        {'role': role},
        where: 'id = ?',
        whereArgs: [userId],
      );
      return true;
    } catch (e) {
      print('Error updating user role: $e');
      return false;
    }
  }

  // Delete user
  Future<bool> deleteUser(String userId) async {
    final db = await database;
    try {
      await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // Check if username exists
  Future<bool> usernameExists(String username) async {
    final db = await database;
    try {
      final results = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );
      return results.isNotEmpty;
    } catch (e) {
      print('Error checking username: $e');
      return true; // Return true to prevent duplicate on error
    }
  }

  // Check if email exists
  Future<bool> emailExists(String email) async {
    final db = await database;
    try {
      final results = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );
      return results.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return true; // Return true to prevent duplicate on error
    }
  }

  // Get user count
  Future<int> getUserCount() async {
    final db = await database;
    try {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Error getting user count: $e');
      return 0;
    }
  }

  // Get CMO count by date range
  Future<Map<String, int>> getCMOCountByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    try {
      final results = await db.rawQuery('''
        SELECT
          DATE(created_at) as date,
          COUNT(*) as count
        FROM cmo_requests
        WHERE created_at >= ? AND created_at <= ?
        GROUP BY DATE(created_at)
        ORDER BY date ASC
      ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

      Map<String, int> countByDate = {};
      for (var row in results) {
        countByDate[row['date'] as String] = row['count'] as int;
      }
      return countByDate;
    } catch (e) {
      print('Error getting CMO count by date: $e');
      return {};
    }
  }

  // Get CMO statistics summary
  Future<Map<String, dynamic>> getCMOStatistics() async {
    final db = await database;
    try {
      final total = await db.rawQuery('SELECT COUNT(*) as count FROM cmo_requests');
      final draft = await db.rawQuery("SELECT COUNT(*) as count FROM cmo_requests WHERE status = 'draft'");
      final pending = await db.rawQuery("SELECT COUNT(*) as count FROM cmo_requests WHERE status = 'pending'");
      final uploaded = await db.rawQuery("SELECT COUNT(*) as count FROM cmo_requests WHERE status = 'uploaded'");
      final synced = await db.rawQuery("SELECT COUNT(*) as count FROM cmo_requests WHERE is_synced = 1");
      final withLocation = await db.rawQuery("SELECT COUNT(*) as count FROM cmo_requests WHERE new_meter_latitude IS NOT NULL");

      // Today's CMOs
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayCMOs = await db.rawQuery(
        "SELECT COUNT(*) as count FROM cmo_requests WHERE created_at >= ?",
        [todayStart.toIso8601String()],
      );

      // This week's CMOs
      final weekStart = todayStart.subtract(Duration(days: today.weekday - 1));
      final weekCMOs = await db.rawQuery(
        "SELECT COUNT(*) as count FROM cmo_requests WHERE created_at >= ?",
        [weekStart.toIso8601String()],
      );

      // This month's CMOs
      final monthStart = DateTime(today.year, today.month, 1);
      final monthCMOs = await db.rawQuery(
        "SELECT COUNT(*) as count FROM cmo_requests WHERE created_at >= ?",
        [monthStart.toIso8601String()],
      );

      return {
        'total': Sqflite.firstIntValue(total) ?? 0,
        'draft': Sqflite.firstIntValue(draft) ?? 0,
        'pending': Sqflite.firstIntValue(pending) ?? 0,
        'uploaded': Sqflite.firstIntValue(uploaded) ?? 0,
        'synced': Sqflite.firstIntValue(synced) ?? 0,
        'withLocation': Sqflite.firstIntValue(withLocation) ?? 0,
        'today': Sqflite.firstIntValue(todayCMOs) ?? 0,
        'thisWeek': Sqflite.firstIntValue(weekCMOs) ?? 0,
        'thisMonth': Sqflite.firstIntValue(monthCMOs) ?? 0,
      };
    } catch (e) {
      print('Error getting CMO statistics: $e');
      return {};
    }
  }

  // Get top users by CMO count
  Future<List<Map<String, dynamic>>> getTopUsersByCMOCount({int limit = 10}) async {
    final db = await database;
    try {
      final results = await db.rawQuery('''
        SELECT
          u.id,
          u.username,
          u.fullName,
          COUNT(c.id) as cmo_count
        FROM users u
        LEFT JOIN cmo_requests c ON u.id = c.user_id
        GROUP BY u.id
        ORDER BY cmo_count DESC
        LIMIT ?
      ''', [limit]);
      return results;
    } catch (e) {
      print('Error getting top users: $e');
      return [];
    }
  }

  // Meter reading operations
  Future<String?> createMeterReading(MeterReading reading) async {
    final db = await database;
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final data = reading.toMap();
      data['id'] = id;

      await db.insert('meter_readings', data);
      return id;
    } catch (e) {
      print('Error creating meter reading: $e');
      return null;
    }
  }

  Future<List<MeterReading>> getAllMeterReadings({String? userId}) async {
    final db = await database;
    try {
      List<Map<String, dynamic>> results;

      if (userId != null) {
        results = await db.query(
          'meter_readings',
          where: 'userId = ?',
          whereArgs: [userId],
          orderBy: 'readingDate DESC',
        );
      } else {
        results = await db.query(
          'meter_readings',
          orderBy: 'readingDate DESC',
        );
      }

      return results.map((map) => MeterReading.fromMap(map)).toList();
    } catch (e) {
      print('Error getting meter readings: $e');
      return [];
    }
  }

  Future<List<MeterReading>> getUnsyncedReadings() async {
    final db = await database;
    try {
      final results = await db.query(
        'meter_readings',
        where: 'isSynced = ?',
        whereArgs: [0],
        orderBy: 'readingDate DESC',
      );

      return results.map((map) => MeterReading.fromMap(map)).toList();
    } catch (e) {
      print('Error getting unsynced readings: $e');
      return [];
    }
  }

  Future<bool> updateMeterReading(MeterReading reading) async {
    final db = await database;
    try {
      await db.update(
        'meter_readings',
        reading.toMap(),
        where: 'id = ?',
        whereArgs: [reading.id],
      );
      return true;
    } catch (e) {
      print('Error updating meter reading: $e');
      return false;
    }
  }

  Future<bool> deleteMeterReading(String id) async {
    final db = await database;
    try {
      await db.delete(
        'meter_readings',
        where: 'id = ?',
        whereArgs: [id],
      );
      return true;
    } catch (e) {
      print('Error deleting meter reading: $e');
      return false;
    }
  }

  Future<MeterReading?> getMeterReadingById(String id) async {
    final db = await database;
    try {
      final results = await db.query(
        'meter_readings',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (results.isNotEmpty) {
        return MeterReading.fromMap(results.first);
      }
      return null;
    } catch (e) {
      print('Error getting meter reading: $e');
      return null;
    }
  }

  Future<List<MeterReading>> searchMeterReadings(String query) async {
    final db = await database;
    try {
      final results = await db.query(
        'meter_readings',
        where: 'meterNumber LIKE ? OR consumerName LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'readingDate DESC',
      );

      return results.map((map) => MeterReading.fromMap(map)).toList();
    } catch (e) {
      print('Error searching meter readings: $e');
      return [];
    }
  }

  // CMO operations
  Future<String?> createCMO(CMO cmo) async {
    final db = await database;
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final data = cmo.toMap();
      data['id'] = id;
      data['created_at'] = DateTime.now().toIso8601String();

      await db.insert('cmo_requests', data);
      return id;
    } catch (e) {
      print('Error creating CMO: $e');
      return null;
    }
  }

  Future<bool> updateCMO(CMO cmo) async {
    final db = await database;
    try {
      final data = cmo.toMap();
      data['updated_at'] = DateTime.now().toIso8601String();

      await db.update(
        'cmo_requests',
        data,
        where: 'id = ?',
        whereArgs: [cmo.id],
      );
      return true;
    } catch (e) {
      print('Error updating CMO: $e');
      return false;
    }
  }

  Future<List<CMO>> getAllCMOs({String? userId}) async {
    final db = await database;
    try {
      List<Map<String, dynamic>> results;

      if (userId != null) {
        results = await db.query(
          'cmo_requests',
          where: 'user_id = ?',
          whereArgs: [userId],
          orderBy: 'created_at DESC',
        );
      } else {
        results = await db.query(
          'cmo_requests',
          orderBy: 'created_at DESC',
        );
      }

      return results.map((map) => CMO.fromMap(map)).toList();
    } catch (e) {
      print('Error getting CMOs: $e');
      return [];
    }
  }

  Future<List<CMO>> getCMOsByStatus(String status, {String? userId}) async {
    final db = await database;
    try {
      List<Map<String, dynamic>> results;

      if (userId != null) {
        results = await db.query(
          'cmo_requests',
          where: 'status = ? AND user_id = ?',
          whereArgs: [status, userId],
          orderBy: 'created_at DESC',
        );
      } else {
        results = await db.query(
          'cmo_requests',
          where: 'status = ?',
          whereArgs: [status],
          orderBy: 'created_at DESC',
        );
      }

      return results.map((map) => CMO.fromMap(map)).toList();
    } catch (e) {
      print('Error getting CMOs by status: $e');
      return [];
    }
  }

  Future<CMO?> getCMOById(String id) async {
    final db = await database;
    try {
      final results = await db.query(
        'cmo_requests',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (results.isNotEmpty) {
        return CMO.fromMap(results.first);
      }
      return null;
    } catch (e) {
      print('Error getting CMO: $e');
      return null;
    }
  }

  Future<bool> deleteCMO(String id) async {
    final db = await database;
    try {
      await db.delete(
        'cmo_requests',
        where: 'id = ?',
        whereArgs: [id],
      );
      return true;
    } catch (e) {
      print('Error deleting CMO: $e');
      return false;
    }
  }

  Future<List<CMO>> searchCMOs(String query) async {
    final db = await database;
    try {
      final results = await db.query(
        'cmo_requests',
        where: 'customer_name LIKE ? OR customer_id LIKE ? OR mobile_number LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'created_at DESC',
      );

      return results.map((map) => CMO.fromMap(map)).toList();
    } catch (e) {
      print('Error searching CMOs: $e');
      return [];
    }
  }

  // Mark CMO as synced
  Future<bool> markCMOAsSynced(String id) async {
    final db = await database;
    try {
      await db.update(
        'cmo_requests',
        {
          'is_synced': 1,
          'synced_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return true;
    } catch (e) {
      print('Error marking CMO as synced: $e');
      return false;
    }
  }

  // Get uploaded but not synced CMOs
  // Only returns CMOs that have new_meter_id filled (required for sync)
  Future<List<CMO>> getUploadedUnsyncedCMOs() async {
    final db = await database;
    try {
      final results = await db.query(
        'cmo_requests',
        where: 'status = ? AND is_synced = ? AND new_meter_id IS NOT NULL AND new_meter_id != ?',
        whereArgs: ['uploaded', 0, ''],
        orderBy: 'created_at DESC',
      );

      return results.map((map) => CMO.fromMap(map)).toList();
    } catch (e) {
      print('Error getting uploaded unsynced CMOs: $e');
      return [];
    }
  }

  // Get count of uploaded but not synced CMOs
  // Only counts CMOs that have new_meter_id filled (required for sync)
  Future<int> getUploadedUnsyncedCount() async {
    final db = await database;
    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM cmo_requests WHERE status = ? AND is_synced = ? AND new_meter_id IS NOT NULL AND new_meter_id != ?',
        ['uploaded', 0, ''],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Error getting unsynced count: $e');
      return 0;
    }
  }

  // Get synced CMOs count
  Future<int> getSyncedCMOsCount() async {
    final db = await database;
    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM cmo_requests WHERE is_synced = ?',
        [1],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Error getting synced count: $e');
      return 0;
    }
  }

  // Customer operations
  Future<String?> createOrUpdateCustomer(Customer customer) async {
    final db = await database;
    try {
      final id = customer.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final data = customer.toMap();
      data['id'] = id;
      data['synced_at'] = DateTime.now().toIso8601String();

      await db.insert(
        'customers',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      print('Error creating/updating customer: $e');
      return null;
    }
  }

  Future<Customer?> getCustomerByOldConsumerId(String oldConsumerId) async {
    final db = await database;
    try {
      final results = await db.query(
        'customers',
        where: 'old_consumer_id = ?',
        whereArgs: [oldConsumerId],
      );

      if (results.isNotEmpty) {
        return Customer.fromMap(results.first);
      }
      return null;
    } catch (e) {
      print('Error getting customer: $e');
      return null;
    }
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    try {
      final results = await db.query(
        'customers',
        orderBy: 'customer_name ASC',
      );

      return results.map((map) => Customer.fromMap(map)).toList();
    } catch (e) {
      print('Error getting all customers: $e');
      return [];
    }
  }

  Future<int> bulkInsertCustomers(List<Customer> customers) async {
    final db = await database;
    int count = 0;
    try {
      final batch = db.batch();

      for (var customer in customers) {
        final id = customer.id ?? DateTime.now().millisecondsSinceEpoch.toString();
        final data = customer.toMap();
        data['id'] = id;
        data['synced_at'] = DateTime.now().toIso8601String();

        batch.insert(
          'customers',
          data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final results = await batch.commit();
      count = results.length;
      print('Bulk inserted $count customers');
      return count;
    } catch (e) {
      print('Error bulk inserting customers: $e');
      return count;
    }
  }

  Future<bool> deleteAllCustomers() async {
    final db = await database;
    try {
      await db.delete('customers');
      return true;
    } catch (e) {
      print('Error deleting all customers: $e');
      return false;
    }
  }

  Future<int> getCustomerCount() async {
    final db = await database;
    try {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM customers');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Error getting customer count: $e');
      return 0;
    }
  }

  // Get CMOs with valid coordinates for map display
  Future<List<CMO>> getCMOsWithCoordinates({String? userId}) async {
    final db = await database;
    try {
      List<Map<String, dynamic>> results;

      if (userId != null) {
        results = await db.query(
          'cmo_requests',
          where: 'user_id = ? AND new_meter_latitude IS NOT NULL AND new_meter_longitude IS NOT NULL',
          whereArgs: [userId],
          orderBy: 'created_at DESC',
        );
      } else {
        results = await db.query(
          'cmo_requests',
          where: 'new_meter_latitude IS NOT NULL AND new_meter_longitude IS NOT NULL',
          orderBy: 'created_at DESC',
        );
      }

      return results.map((map) => CMO.fromMap(map)).toList();
    } catch (e) {
      print('Error getting CMOs with coordinates: $e');
      return [];
    }
  }

  // Search CMOs by meter number or customer ID
  Future<List<CMO>> searchCMOsByMeterOrCustomerId(String query) async {
    final db = await database;
    try {
      final results = await db.query(
        'cmo_requests',
        where: 'old_meter_number LIKE ? OR customer_id LIKE ? OR new_meter_id LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'created_at DESC',
      );

      return results.map((map) => CMO.fromMap(map)).toList();
    } catch (e) {
      print('Error searching CMOs by meter/customer ID: $e');
      return [];
    }
  }

  // ==================== BULK CMO OPERATIONS ====================

  // Create bulk CMO group
  Future<String?> createBulkCMOGroup(BulkCMOGroup group) async {
    final db = await database;
    try {
      final id = 'bulk-${DateTime.now().millisecondsSinceEpoch}';
      final data = group.toMap();
      data['id'] = id;
      data['created_at'] = DateTime.now().toIso8601String();

      await db.insert('bulk_cmo_groups', data);
      return id;
    } catch (e) {
      print('Error creating bulk CMO group: $e');
      return null;
    }
  }

  // Update bulk CMO group
  Future<bool> updateBulkCMOGroup(BulkCMOGroup group) async {
    final db = await database;
    try {
      final data = group.toMap();
      data['updated_at'] = DateTime.now().toIso8601String();

      await db.update(
        'bulk_cmo_groups',
        data,
        where: 'id = ?',
        whereArgs: [group.id],
      );
      return true;
    } catch (e) {
      print('Error updating bulk CMO group: $e');
      return false;
    }
  }

  // Get bulk CMO group by ID
  Future<BulkCMOGroup?> getBulkCMOGroupById(String id) async {
    final db = await database;
    try {
      final results = await db.query(
        'bulk_cmo_groups',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (results.isNotEmpty) {
        return BulkCMOGroup.fromMap(results.first);
      }
      return null;
    } catch (e) {
      print('Error getting bulk CMO group: $e');
      return null;
    }
  }

  // Get all bulk CMO groups
  Future<List<BulkCMOGroup>> getAllBulkCMOGroups({String? status}) async {
    final db = await database;
    try {
      List<Map<String, dynamic>> results;

      if (status != null) {
        results = await db.query(
          'bulk_cmo_groups',
          where: 'status = ?',
          whereArgs: [status],
          orderBy: 'created_at DESC',
        );
      } else {
        results = await db.query(
          'bulk_cmo_groups',
          orderBy: 'created_at DESC',
        );
      }

      return results.map((map) => BulkCMOGroup.fromMap(map)).toList();
    } catch (e) {
      print('Error getting bulk CMO groups: $e');
      return [];
    }
  }

  // Delete bulk CMO group
  Future<bool> deleteBulkCMOGroup(String id) async {
    final db = await database;
    try {
      // Delete associated meter entries first
      await db.delete(
        'bulk_meter_entries',
        where: 'bulk_group_id = ?',
        whereArgs: [id],
      );

      // Delete the group
      await db.delete(
        'bulk_cmo_groups',
        where: 'id = ?',
        whereArgs: [id],
      );
      return true;
    } catch (e) {
      print('Error deleting bulk CMO group: $e');
      return false;
    }
  }

  // Create bulk meter entry
  Future<String?> createBulkMeterEntry(BulkMeterEntry entry) async {
    final db = await database;
    try {
      final id = 'entry-${DateTime.now().millisecondsSinceEpoch}-${entry.meterIndex}';
      final data = entry.toMap();
      data['id'] = id;

      await db.insert('bulk_meter_entries', data);
      return id;
    } catch (e) {
      print('Error creating bulk meter entry: $e');
      return null;
    }
  }

  // Update bulk meter entry
  Future<bool> updateBulkMeterEntry(BulkMeterEntry entry) async {
    final db = await database;
    try {
      await db.update(
        'bulk_meter_entries',
        entry.toMap(),
        where: 'id = ?',
        whereArgs: [entry.id],
      );
      return true;
    } catch (e) {
      print('Error updating bulk meter entry: $e');
      return false;
    }
  }

  // Get meter entries for a bulk group
  Future<List<BulkMeterEntry>> getBulkMeterEntries(String bulkGroupId) async {
    final db = await database;
    try {
      final results = await db.query(
        'bulk_meter_entries',
        where: 'bulk_group_id = ?',
        whereArgs: [bulkGroupId],
        orderBy: 'meter_index ASC',
      );

      return results.map((map) => BulkMeterEntry.fromMap(map)).toList();
    } catch (e) {
      print('Error getting bulk meter entries: $e');
      return [];
    }
  }

  // Delete bulk meter entry
  Future<bool> deleteBulkMeterEntry(String id) async {
    final db = await database;
    try {
      await db.delete(
        'bulk_meter_entries',
        where: 'id = ?',
        whereArgs: [id],
      );
      return true;
    } catch (e) {
      print('Error deleting bulk meter entry: $e');
      return false;
    }
  }

  // Create CMO with bulk group reference
  Future<String?> createCMOWithBulkGroup(CMO cmo, String bulkGroupId, int meterIndex) async {
    final db = await database;
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final data = cmo.toMap();
      data['id'] = id;
      data['bulk_group_id'] = bulkGroupId;
      data['meter_index'] = meterIndex;

      await db.insert('cmo_requests', data);
      return id;
    } catch (e) {
      print('Error creating CMO with bulk group: $e');
      return null;
    }
  }

  // Get CMOs by bulk group ID
  Future<List<CMO>> getCMOsByBulkGroupId(String bulkGroupId) async {
    final db = await database;
    try {
      final results = await db.query(
        'cmo_requests',
        where: 'bulk_group_id = ?',
        whereArgs: [bulkGroupId],
        orderBy: 'meter_index ASC',
      );

      return results.map((map) => CMO.fromMap(map)).toList();
    } catch (e) {
      print('Error getting CMOs by bulk group: $e');
      return [];
    }
  }

  // Update bulk group completion count
  Future<bool> updateBulkGroupCompletedCount(String bulkGroupId) async {
    final db = await database;
    try {
      // Count completed entries
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM bulk_meter_entries WHERE bulk_group_id = ? AND is_complete = 1',
        [bulkGroupId],
      );
      final completedCount = Sqflite.firstIntValue(result) ?? 0;

      // Get total meter count
      final group = await getBulkCMOGroupById(bulkGroupId);
      if (group == null) return false;

      // Determine status
      String newStatus;
      if (completedCount == 0) {
        newStatus = 'draft';
      } else if (completedCount < group.meterCount) {
        newStatus = 'partial';
      } else {
        newStatus = 'complete';
      }

      await db.update(
        'bulk_cmo_groups',
        {
          'completed_count': completedCount,
          'status': newStatus,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [bulkGroupId],
      );

      return true;
    } catch (e) {
      print('Error updating bulk group completed count: $e');
      return false;
    }
  }

  // Get uploaded unsynced bulk groups (for sync)
  Future<List<BulkCMOGroup>> getUploadedUnsyncedBulkGroups() async {
    final db = await database;
    try {
      final results = await db.query(
        'bulk_cmo_groups',
        where: 'status = ?',
        whereArgs: ['uploaded'],
        orderBy: 'created_at DESC',
      );

      return results.map((map) => BulkCMOGroup.fromMap(map)).toList();
    } catch (e) {
      print('Error getting uploaded unsynced bulk groups: $e');
      return [];
    }
  }

  // Mark bulk group as synced
  Future<bool> markBulkGroupAsSynced(String id) async {
    final db = await database;
    try {
      await db.update(
        'bulk_cmo_groups',
        {
          'status': 'synced',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return true;
    } catch (e) {
      print('Error marking bulk group as synced: $e');
      return false;
    }
  }

  // Get bulk group count by status
  Future<Map<String, int>> getBulkGroupCounts() async {
    final db = await database;
    try {
      final draft = await db.rawQuery(
        'SELECT COUNT(*) as count FROM bulk_cmo_groups WHERE status = ?',
        ['draft'],
      );
      final partial = await db.rawQuery(
        'SELECT COUNT(*) as count FROM bulk_cmo_groups WHERE status = ?',
        ['partial'],
      );
      final complete = await db.rawQuery(
        'SELECT COUNT(*) as count FROM bulk_cmo_groups WHERE status = ?',
        ['complete'],
      );
      final uploaded = await db.rawQuery(
        'SELECT COUNT(*) as count FROM bulk_cmo_groups WHERE status = ?',
        ['uploaded'],
      );
      final synced = await db.rawQuery(
        'SELECT COUNT(*) as count FROM bulk_cmo_groups WHERE status = ?',
        ['synced'],
      );

      return {
        'draft': Sqflite.firstIntValue(draft) ?? 0,
        'partial': Sqflite.firstIntValue(partial) ?? 0,
        'complete': Sqflite.firstIntValue(complete) ?? 0,
        'uploaded': Sqflite.firstIntValue(uploaded) ?? 0,
        'synced': Sqflite.firstIntValue(synced) ?? 0,
      };
    } catch (e) {
      print('Error getting bulk group counts: $e');
      return {'draft': 0, 'partial': 0, 'complete': 0, 'uploaded': 0, 'synced': 0};
    }
  }

  // Get CMO status counts for a specific bulk group
  Future<Map<String, int>> getCMOStatusCountsByBulkGroup(String bulkGroupId) async {
    final db = await database;
    try {
      final draft = await db.rawQuery(
        'SELECT COUNT(*) as count FROM cmo_requests WHERE bulk_group_id = ? AND status = ? AND is_synced = 0',
        [bulkGroupId, 'draft'],
      );
      final uploaded = await db.rawQuery(
        'SELECT COUNT(*) as count FROM cmo_requests WHERE bulk_group_id = ? AND status = ? AND is_synced = 0',
        [bulkGroupId, 'uploaded'],
      );
      final synced = await db.rawQuery(
        'SELECT COUNT(*) as count FROM cmo_requests WHERE bulk_group_id = ? AND is_synced = 1',
        [bulkGroupId],
      );
      final total = await db.rawQuery(
        'SELECT COUNT(*) as count FROM cmo_requests WHERE bulk_group_id = ?',
        [bulkGroupId],
      );

      return {
        'draft': Sqflite.firstIntValue(draft) ?? 0,
        'uploaded': Sqflite.firstIntValue(uploaded) ?? 0,
        'synced': Sqflite.firstIntValue(synced) ?? 0,
        'total': Sqflite.firstIntValue(total) ?? 0,
      };
    } catch (e) {
      print('Error getting CMO status counts by bulk group: $e');
      return {'draft': 0, 'uploaded': 0, 'synced': 0, 'total': 0};
    }
  }

  // ==================== DUPLICATE CHECK METHODS ====================

  /// Check if customer ID already exists locally (excluding a specific CMO id for edit mode)
  Future<bool> isCustomerIdDuplicate(String customerId, {String? excludeCmoId}) async {
    final db = await database;
    try {
      String query = 'SELECT COUNT(*) as count FROM cmo_requests WHERE customer_id = ?';
      List<dynamic> args = [customerId];

      if (excludeCmoId != null) {
        query += ' AND id != ?';
        args.add(excludeCmoId);
      }

      final result = await db.rawQuery(query, args);
      final count = Sqflite.firstIntValue(result) ?? 0;
      return count > 0;
    } catch (e) {
      print('Error checking customer ID duplicate: $e');
      return false;
    }
  }

  /// Check if new meter ID already exists locally (excluding a specific CMO id for edit mode)
  Future<bool> isNewMeterIdDuplicate(String newMeterId, {String? excludeCmoId}) async {
    final db = await database;
    try {
      String query = 'SELECT COUNT(*) as count FROM cmo_requests WHERE new_meter_id = ?';
      List<dynamic> args = [newMeterId];

      if (excludeCmoId != null) {
        query += ' AND id != ?';
        args.add(excludeCmoId);
      }

      final result = await db.rawQuery(query, args);
      final count = Sqflite.firstIntValue(result) ?? 0;
      return count > 0;
    } catch (e) {
      print('Error checking new meter ID duplicate: $e');
      return false;
    }
  }

  /// Get existing CMO by customer ID (for showing duplicate details)
  Future<CMO?> getCMOByCustomerId(String customerId) async {
    final db = await database;
    try {
      final results = await db.query(
        'cmo_requests',
        where: 'customer_id = ?',
        whereArgs: [customerId],
        limit: 1,
      );

      if (results.isNotEmpty) {
        return CMO.fromMap(results.first);
      }
      return null;
    } catch (e) {
      print('Error getting CMO by customer ID: $e');
      return null;
    }
  }

  /// Get existing CMO by new meter ID (for showing duplicate details)
  Future<CMO?> getCMOByNewMeterId(String newMeterId) async {
    final db = await database;
    try {
      final results = await db.query(
        'cmo_requests',
        where: 'new_meter_id = ?',
        whereArgs: [newMeterId],
        limit: 1,
      );

      if (results.isNotEmpty) {
        return CMO.fromMap(results.first);
      }
      return null;
    } catch (e) {
      print('Error getting CMO by new meter ID: $e');
      return null;
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
