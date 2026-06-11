import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Opens (and on first run, creates + seeds) the local SQLite database.
///
/// One file `event_hall.db` with four tables: halls, bookings, payments, users.
/// Seed data is inserted in [_onCreate] the first time the DB is created, and
/// can be re-applied at any time with [reseed] (used by the admin "Seed
/// Database" button).
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'event_hall.db';
  static const _assetPath = 'assets/databases/event_hall.db';
  static const _dbVersion = 3;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);

    // First launch: copy the prebuilt, already-populated database that ships
    // as an asset. If the asset is missing, fall back to creating + seeding
    // the tables in code (via _onCreate).
    if (!await databaseExists(path)) {
      try {
        await Directory(p.dirname(path)).create(recursive: true);
        final data = await rootBundle.load(_assetPath);
        final bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        // ignore: avoid_print
        debugPrint('Prebuilt DB asset not found, will create + seed: $e');
      }
    }

    return openDatabase(path,
        version: _dbVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  /// Absolute path of the live database file.
  Future<String> get databaseFilePath async {
    final dir = await getDatabasesPath();
    return p.join(dir, _dbName);
  }

  /// Copies the live database to a folder you can actually browse:
  ///   Android: /storage/emulated/0/Android/data/<package>/files/event_hall.db
  /// Returns the destination path.
  Future<String> exportToAccessibleFolder() async {
    await database; // ensure it exists
    final srcPath = await databaseFilePath;

    Directory? destDir = await getExternalStorageDirectory();
    destDir ??= await getApplicationDocumentsDirectory();

    final destPath = p.join(destDir.path, _dbName);
    await File(srcPath).copy(destPath);
    return destPath;
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _seed(db);
  }

  /// Migrations for databases created by an older app version (including the
  /// prebuilt asset DB shipped at v1).
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v2: users now stores an `upcoming` count so the profile screen can read
      // all of its stats from the single users record. Backfill existing rows
      // from the live bookings table so the value is correct without a reseed.
      await _addColumnIfMissing(db, 'users', 'upcoming', 'INTEGER');
      final counts = await db.rawQuery('''
        SELECT u.id AS id,
          (SELECT COUNT(*) FROM bookings b
             WHERE b.userEmail = u.email COLLATE NOCASE AND b.upcoming = 1) AS up
        FROM users u
      ''');
      final batch = db.batch();
      for (final row in counts) {
        batch.update('users', {'upcoming': (row['up'] as int?) ?? 0},
            where: 'id = ?', whereArgs: [row['id']]);
      }
      await batch.commit(noResult: true);
    }
    // v3 reserved: previously recomputed users.spent from payments; removed so
    // the stored spent value is preserved as the source of truth.
  }

  Future<void> _addColumnIfMissing(
      Database db, String table, String column, String type) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final exists = info.any((c) => c['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE halls (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT, type TEXT, location TEXT,
        capacity INTEGER, rating REAL, reviewCount INTEGER,
        price_per_day REAL, price_per_hr REAL, price TEXT,
        status TEXT, statusType TEXT, isActive INTEGER,
        amenities TEXT, description TEXT, image_url TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ref TEXT, hallId TEXT, hallName TEXT,
        userName TEXT, userEmail TEXT,
        date TEXT, timeSlot TEXT, amount REAL,
        status TEXT, upcoming INTEGER, createdAt INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        txn TEXT, bookingRef TEXT,
        userName TEXT, userEmail TEXT, hallName TEXT,
        amount REAL, method TEXT, status TEXT,
        date TEXT, timestamp INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT, email TEXT, phone TEXT, role TEXT,
        bookings INTEGER, spent TEXT, status TEXT,
        initials TEXT, avatarColor INTEGER, textColor INTEGER, joined TEXT,
        upcoming INTEGER
      )
    ''');
  }

  /// Wipes every table and re-inserts the demo data. Returns row counts.
  Future<Map<String, int>> reseed() async {
    final db = await database;
    await db.delete('halls');
    await db.delete('bookings');
    await db.delete('payments');
    await db.delete('users');
    await _seed(db);
    return {
      'halls': _halls.length,
      'bookings': _bookings.length,
      'payments': _payments.length,
      'users': _users.length,
    };
  }

  Future<void> _seed(Database db) async {
    final batch = db.batch();
    for (final h in _halls) {
      batch.insert('halls', h);
    }
    for (final b in _bookings) {
      batch.insert('bookings', b);
    }
    for (final pay in _payments) {
      batch.insert('payments', pay);
    }
    for (final u in _users) {
      batch.insert('users', u);
    }
    await batch.commit(noResult: true);
  }

  /// millisecondsSinceEpoch for a "d MMM yyyy" demo date string.
  static int _ts(String date) {
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final parts = date.split(' ');
    final day = int.tryParse(parts[0]) ?? 1;
    final month = months[parts[1]] ?? 1;
    final year = int.tryParse(parts[2]) ?? 2025;
    return DateTime(year, month, day, 10).millisecondsSinceEpoch;
  }

  // ── Seed data ─────────────────────────────────────────────────────────────
  // amenities are stored as a single '|'-joined string (split on read).

  static final List<Map<String, Object?>> _halls = [
    {
      'name': 'Grand Ballroom A', 'type': 'Event Hall', 'location': 'KL City',
      'capacity': 500, 'rating': 4.8, 'reviewCount': 124,
      'price_per_day': 2500.0, 'price_per_hr': 0.0, 'price': 'RM 2,500/day',
      'status': 'Available', 'statusType': 'success', 'isActive': 1,
      'amenities': '📽 Projector|🎤 PA System|❄️ AC|🅿️ Parking',
      'description':
          'Elegant grand ballroom ideal for weddings, galas and large corporate events.',
      'image_url':
          'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?q=80&w=1000',
    },
    {
      'name': 'Executive Boardroom', 'type': 'Conference', 'location': 'Petaling Jaya',
      'capacity': 20, 'rating': 4.6, 'reviewCount': 58,
      'price_per_day': 0.0, 'price_per_hr': 350.0, 'price': 'RM 350/hr',
      'status': 'Limited', 'statusType': 'warning', 'isActive': 1,
      'amenities': '📺 TV Screen|☕ Coffee|🌐 WiFi',
      'description':
          'Premium executive boardroom for high-level meetings and presentations.',
      'image_url':
          'https://images.unsplash.com/photo-1431540015161-0bf868a2d407?q=80&w=1000',
    },
    {
      'name': 'Training Room B', 'type': 'Training', 'location': 'KLCC',
      'capacity': 40, 'rating': 4.5, 'reviewCount': 73,
      'price_per_day': 0.0, 'price_per_hr': 180.0, 'price': 'RM 180/hr',
      'status': 'Available', 'statusType': 'success', 'isActive': 1,
      'amenities': '💻 Computers|📽 Projector|❄️ AC',
      'description':
          'Fully-equipped training room with workstations for workshops and courses.',
      'image_url':
          'https://images.unsplash.com/photo-1524178232363-1fb2b075b655?q=80&w=1000',
    },
    {
      'name': 'Banquet Hall Omega', 'type': 'Banquet', 'location': 'Ampang',
      'capacity': 300, 'rating': 4.7, 'reviewCount': 96,
      'price_per_day': 1800.0, 'price_per_hr': 0.0, 'price': 'RM 1,800/day',
      'status': 'Available', 'statusType': 'success', 'isActive': 1,
      'amenities': '🍽 Catering|🎵 Sound System|🅿️ Parking',
      'description':
          'Spacious banquet hall with in-house catering for celebrations and dinners.',
      'image_url':
          'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?q=80&w=1000',
    },
    {
      'name': 'Crystal Meeting Room', 'type': 'Conference', 'location': 'Mont Kiara',
      'capacity': 12, 'rating': 4.4, 'reviewCount': 41,
      'price_per_day': 0.0, 'price_per_hr': 200.0, 'price': 'RM 200/hr',
      'status': 'Available', 'statusType': 'success', 'isActive': 1,
      'amenities': '📺 TV|☕ Coffee|🌐 WiFi',
      'description':
          'Bright, modern meeting room perfect for small team discussions.',
      'image_url':
          'https://images.unsplash.com/photo-1497366216548-37526070297c?q=80&w=1000',
    },
  ];

  static final List<Map<String, Object?>> _bookings = [
    {
      'ref': 'BK-20250415-0032', 'hallId': '', 'hallName': 'Grand Ballroom A',
      'userName': 'Ahmad Hassan', 'userEmail': 'ahmad@example.com',
      'date': '15 Apr 2025', 'timeSlot': '10:00–12:00', 'amount': 11600.0,
      'status': 'Confirmed', 'upcoming': 1, 'createdAt': _ts('15 Apr 2025'),
    },
    {
      'ref': 'BK-20250422-0019', 'hallId': '', 'hallName': 'Executive Boardroom',
      'userName': 'Siti Nora', 'userEmail': 'siti@example.com',
      'date': '22 Apr 2025', 'timeSlot': '14:00–16:00', 'amount': 700.0,
      'status': 'Pending', 'upcoming': 1, 'createdAt': _ts('22 Apr 2025'),
    },
    {
      'ref': 'BK-20250301-0008', 'hallId': '', 'hallName': 'Training Room B',
      'userName': 'David Lim', 'userEmail': 'david@example.com',
      'date': '1 Mar 2025', 'timeSlot': '9:00–12:00', 'amount': 540.0,
      'status': 'Completed', 'upcoming': 0, 'createdAt': _ts('1 Mar 2025'),
    },
    {
      'ref': 'BK-20250210-0003', 'hallId': '', 'hallName': 'Banquet Hall Omega',
      'userName': 'Nurul Ain', 'userEmail': 'nurul@example.com',
      'date': '10 Feb 2025', 'timeSlot': '18:00–22:00', 'amount': 3200.0,
      'status': 'Cancelled', 'upcoming': 0, 'createdAt': _ts('10 Feb 2025'),
    },
    {
      'ref': 'BK-20250501-0041', 'hallId': '', 'hallName': 'Grand Ballroom A',
      'userName': 'Kevin Tan', 'userEmail': 'kevin@example.com',
      'date': '1 May 2025', 'timeSlot': '8:00–12:00', 'amount': 5400.0,
      'status': 'Pending', 'upcoming': 1, 'createdAt': _ts('1 May 2025'),
    },
    {
      'ref': 'BK-20250215-0004', 'hallId': '', 'hallName': 'Executive Boardroom',
      'userName': 'Nurul Ain', 'userEmail': 'nurul@example.com',
      'date': '15 Feb 2025', 'timeSlot': '11:00–13:00', 'amount': 700.0,
      'status': 'Cancelled', 'upcoming': 0, 'createdAt': _ts('15 Feb 2025'),
    },
    {
      'ref': 'BK-20250110-0012', 'hallId': '', 'hallName': 'Banquet Hall Omega',
      'userName': 'Ahmad Hassan', 'userEmail': 'ahmad@example.com',
      'date': '10 Jan 2025', 'timeSlot': '18:00–23:00', 'amount': 3200.0,
      'status': 'Completed', 'upcoming': 0, 'createdAt': _ts('10 Jan 2025'),
    },
    {
      'ref': 'BK-20250602-0050', 'hallId': '', 'hallName': 'Crystal Meeting Room',
      'userName': 'Kevin Tan', 'userEmail': 'kevin@example.com',
      'date': '2 Jun 2025', 'timeSlot': '9:00–11:00', 'amount': 400.0,
      'status': 'Pending', 'upcoming': 1, 'createdAt': _ts('2 Jun 2025'),
    },
  ];

  static final List<Map<String, Object?>> _payments = [
    {
      'txn': 'TXN-20250415-8821', 'bookingRef': 'BK-20250415-0032',
      'userName': 'Ahmad Hassan', 'userEmail': 'ahmad@example.com',
      'hallName': 'Grand Ballroom A', 'amount': 11600.0, 'method': 'Maybank FPX',
      'status': 'Paid', 'date': '15 Apr 2025, 9:43 AM', 'timestamp': _ts('15 Apr 2025'),
    },
    {
      'txn': 'TXN-20250422-1102', 'bookingRef': 'BK-20250422-0019',
      'userName': 'Siti Nora', 'userEmail': 'siti@example.com',
      'hallName': 'Executive Boardroom', 'amount': 700.0, 'method': 'Credit Card',
      'status': 'Pending', 'date': '22 Apr 2025, 2:10 PM', 'timestamp': _ts('22 Apr 2025'),
    },
    {
      'txn': 'TXN-20250501-3341', 'bookingRef': 'BK-20250501-0041',
      'userName': 'Kevin Tan', 'userEmail': 'kevin@example.com',
      'hallName': 'Grand Ballroom A', 'amount': 5400.0, 'method': 'GrabPay',
      'status': 'Paid', 'date': '1 May 2025, 11:30 AM', 'timestamp': _ts('1 May 2025'),
    },
    {
      'txn': 'TXN-20250301-4412', 'bookingRef': 'BK-20250301-0008',
      'userName': 'David Lim', 'userEmail': 'david@example.com',
      'hallName': 'Training Room B', 'amount': 540.0, 'method': 'Credit Card',
      'status': 'Refunded', 'date': '1 Mar 2025, 8:10 AM', 'timestamp': _ts('1 Mar 2025'),
    },
    {
      'txn': 'TXN-20250215-2201', 'bookingRef': 'BK-20250215-0004',
      'userName': 'Nurul Ain', 'userEmail': 'nurul@example.com',
      'hallName': 'Executive Boardroom', 'amount': 700.0, 'method': 'TNG eWallet',
      'status': 'Failed', 'date': '15 Feb 2025, 11:00 AM', 'timestamp': _ts('15 Feb 2025'),
    },
    {
      'txn': 'TXN-20250110-1901', 'bookingRef': 'BK-20250110-0012',
      'userName': 'Ahmad Hassan', 'userEmail': 'ahmad@example.com',
      'hallName': 'Banquet Hall Omega', 'amount': 3200.0, 'method': 'GrabPay',
      'status': 'Paid', 'date': '10 Jan 2025, 2:15 PM', 'timestamp': _ts('10 Jan 2025'),
    },
    {
      'txn': 'TXN-20250602-9910', 'bookingRef': 'BK-20250602-0050',
      'userName': 'Kevin Tan', 'userEmail': 'kevin@example.com',
      'hallName': 'Crystal Meeting Room', 'amount': 400.0, 'method': 'Bank Transfer',
      'status': 'Pending', 'date': '2 Jun 2025, 9:00 AM', 'timestamp': _ts('2 Jun 2025'),
    },
  ];

  static final List<Map<String, Object?>> _users = [
    {
      'name': 'Ahmad Hassan', 'email': 'ahmad@example.com', 'phone': '+60 12 345 6789',
      'role': 'user', 'bookings': 2, 'spent': 'RM 14,800', 'status': 'Active',
      'initials': 'AH', 'avatarColor': 0xFFE6F1FB, 'textColor': 0xFF0C447C,
      'joined': '12 Jan 2025', 'upcoming': 1,
    },
    {
      'name': 'Siti Nora', 'email': 'siti@example.com', 'phone': '+60 11 234 5678',
      'role': 'user', 'bookings': 1, 'spent': 'RM 0', 'status': 'Active',
      'initials': 'SN', 'avatarColor': 0xFFFBEAF0, 'textColor': 0xFF72243E,
      'joined': '20 Feb 2025', 'upcoming': 1,
    },
    {
      'name': 'David Lim', 'email': 'david@example.com', 'phone': '+60 16 789 0123',
      'role': 'user', 'bookings': 1, 'spent': 'RM 0', 'status': 'Suspended',
      'initials': 'DL', 'avatarColor': 0xFFF1EFE8, 'textColor': 0xFF444441,
      'joined': '5 Dec 2024', 'upcoming': 0,
    },
    {
      'name': 'Nurul Ain', 'email': 'nurul@example.com', 'phone': '+60 19 456 7890',
      'role': 'user', 'bookings': 2, 'spent': 'RM 0', 'status': 'Active',
      'initials': 'NA', 'avatarColor': 0xFFEAF3DE, 'textColor': 0xFF27500A,
      'joined': '1 Mar 2025', 'upcoming': 0,
    },
    {
      'name': 'Kevin Tan', 'email': 'kevin@example.com', 'phone': '+60 17 321 6540',
      'role': 'user', 'bookings': 2, 'spent': 'RM 5,400', 'status': 'Active',
      'initials': 'KT', 'avatarColor': 0xFFFAEEDA, 'textColor': 0xFF633806,
      'joined': '14 Apr 2025', 'upcoming': 2,
    },
  ];
}
