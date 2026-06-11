import 'package:flutter/foundation.dart' show debugPrint;
import 'package:sqflite/sqflite.dart';
import 'app_events.dart';
import 'database_helper.dart';

/// Single data-access layer backed by local SQLite.
/// Returns plain maps so the existing Map-based screens work directly —
/// same method names the old FirebaseService exposed.
class DbService {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  // ── Halls ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getHalls({String? type}) async {
    try {
      final db = await _db;
      final rows = (type != null && type != 'All')
          ? await db.query('halls', where: 'type = ?', whereArgs: [type])
          : await db.query('halls');
      return rows.map(_hallFromRow).toList();
    } catch (e) {
      debugPrint('Error fetching halls: $e');
      return [];
    }
  }

  Future<bool> addHall(Map<String, dynamic> data) async {
    final ok = await _insert('halls', _hallToRow(data), 'adding hall');
    if (ok) AppEvents.notifyDataChanged();
    return ok;
  }

  Future<bool> updateHall(String id, Map<String, dynamic> data) async {
    try {
      final db = await _db;
      await db.update('halls', _hallToRow(data), where: 'id = ?', whereArgs: [id]);
      AppEvents.notifyDataChanged();
      return true;
    } catch (e) {
      debugPrint('Error updating hall: $e');
      return false;
    }
  }

  Future<bool> deleteHall(String id) async {
    try {
      final db = await _db;
      await db.delete('halls', where: 'id = ?', whereArgs: [id]);
      AppEvents.notifyDataChanged();
      return true;
    } catch (e) {
      debugPrint('Error deleting hall: $e');
      return false;
    }
  }

  // ── Bookings ────────────────────────────────────────────────────────────--

  Future<bool> createBooking(Map<String, dynamic> data) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final amount = data['amount'];
    final row = {
      'ref': data['ref'] ?? 'BK-$now',
      'hallId': (data['hallId'] ?? '').toString(),
      'hallName': data['hallName'] ?? data['name'] ?? '',
      'userName': data['userName'] ?? '',
      'userEmail': data['userEmail'] ?? '',
      'date': data['date'] ?? '',
      'timeSlot': data['timeSlot'] ?? data['slot'] ?? '',
      'amount': (amount is num) ? amount.toDouble() : double.tryParse('$amount') ?? 0.0,
      'status': data['status'] ?? 'Pending',
      'upcoming': (data['upcoming'] == true) ? 1 : 0,
      'createdAt': now,
    };
    final ok = await _insert('bookings', row, 'creating booking');
    if (ok) {
      await _adjustUserStats((row['userEmail'] as String?) ?? '',
          bookingsDelta: 1, upcomingDelta: row['upcoming'] == 1 ? 1 : 0);
      AppEvents.notifyDataChanged();
    }
    return ok;
  }

  Future<List<Map<String, dynamic>>> getMyBookings(String userEmail) async {
    try {
      final db = await _db;
      final rows = await db.query('bookings',
          where: 'userEmail = ? COLLATE NOCASE', whereArgs: [userEmail], orderBy: 'createdAt DESC');
      return rows.map(_bookingFromRow).toList();
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllBookings() async {
    try {
      final db = await _db;
      final rows = await db.query('bookings', orderBy: 'createdAt DESC');
      return rows.map(_bookingFromRow).toList();
    } catch (e) {
      debugPrint('Error fetching all bookings: $e');
      return [];
    }
  }

  Future<bool> updateBookingStatus(String id, String status) async {
    try {
      final db = await _db;
      final newUpcoming = (status == 'Confirmed' || status == 'Pending') ? 1 : 0;
      // Read prior state so we can keep the user's upcoming counter accurate.
      final existing = await db.query('bookings',
          columns: ['userEmail', 'upcoming'],
          where: 'id = ?', whereArgs: [id], limit: 1);
      await db.update(
        'bookings',
        {'status': status, 'upcoming': newUpcoming},
        where: 'id = ?',
        whereArgs: [id],
      );
      if (existing.isNotEmpty) {
        final oldUpcoming = (existing.first['upcoming'] as int?) ?? 0;
        if (newUpcoming != oldUpcoming) {
          await _adjustUserStats((existing.first['userEmail'] ?? '').toString(),
              upcomingDelta: newUpcoming - oldUpcoming);
        }
      }
      AppEvents.notifyDataChanged();
      return true;
    } catch (e) {
      debugPrint('Error updating booking status: $e');
      return false;
    }
  }

  // ── Payments ──────────────────────────────────────────────────────────────

  Future<bool> createPayment(Map<String, dynamic> data) async {
    final row = {...data, 'timestamp': DateTime.now().millisecondsSinceEpoch};
    final ok = await _insert('payments', row, 'recording payment');
    if (ok) {
      if (row['status'] == 'Paid') {
        final amount = (row['amount'] is num)
            ? (row['amount'] as num).toDouble()
            : double.tryParse('${row['amount']}') ?? 0.0;
        await _adjustUserStats((row['userEmail'] as String?) ?? '', spentDelta: amount);
      }
      AppEvents.notifyDataChanged();
    }
    return ok;
  }

  Future<List<Map<String, dynamic>>> getPaymentRecords() async {
    try {
      final db = await _db;
      final rows = await db.query('payments', orderBy: 'timestamp DESC');
      return rows.map((r) => {...r, 'id': r['id'].toString()}).toList();
    } catch (e) {
      debugPrint('Error fetching payments: $e');
      return [];
    }
  }

  Future<bool> updatePaymentStatus(String id, String status) async {
    try {
      final db = await _db;
      // Read prior state so we can add/subtract from the user's spent total
      // whenever a payment crosses into or out of the 'Paid' state.
      final existing = await db.query('payments',
          columns: ['userEmail', 'amount', 'status'],
          where: 'id = ?', whereArgs: [id], limit: 1);
      await db.update('payments', {'status': status},
          where: 'id = ?', whereArgs: [id]);
      if (existing.isNotEmpty) {
        final wasPaid = existing.first['status'] == 'Paid';
        final isPaid = status == 'Paid';
        if (wasPaid != isPaid) {
          final amount = (existing.first['amount'] as num?)?.toDouble() ?? 0.0;
          await _adjustUserStats((existing.first['userEmail'] ?? '').toString(),
              spentDelta: isPaid ? amount : -amount);
        }
      }
      AppEvents.notifyDataChanged();
      return true;
    } catch (e) {
      debugPrint('Error updating payment status: $e');
      return false;
    }
  }

  // ── Users ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final db = await _db;
      final rows = await db.query('users');
      return rows.map((r) => {...r, 'id': r['id'].toString()}).toList();
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  Future<bool> updateUserStatus(String id, String status) async {
    try {
      final db = await _db;
      await db.update('users', {'status': status},
          where: 'id = ?', whereArgs: [id]);
      AppEvents.notifyDataChanged();
      return true;
    } catch (e) {
      debugPrint('Error updating user status: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final db = await _db;
      final rows = await db.query('users',
          where: 'email = ? COLLATE NOCASE', whereArgs: [email], limit: 1);
      if (rows.isEmpty) return null;
      return {...rows.first, 'id': rows.first['id'].toString()};
    } catch (e) {
      debugPrint('Error fetching user: $e');
      return null;
    }
  }

  Future<bool> addUser(Map<String, dynamic> data) =>
      _insert('users', data, 'adding user');

  Future<bool> updateUser(String id, Map<String, dynamic> data) async {
    try {
      final db = await _db;
      await db.update('users', data, where: 'id = ?', whereArgs: [id]);
      AppEvents.notifyDataChanged();
      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }

  /// Keeps the denormalized users.bookings / users.upcoming / users.spent
  /// counters in step with the live bookings & payments tables. Called on every
  /// booking/payment write so the profile (which reads the users row) stays
  /// correct. [spentDelta] is a RM amount (may be negative, e.g. on refund).
  /// No-op for ad-hoc users that aren't stored in the users table.
  Future<void> _adjustUserStats(String email,
      {int bookingsDelta = 0, int upcomingDelta = 0, double spentDelta = 0.0}) async {
    if (email.isEmpty) return;
    try {
      final db = await _db;
      final rows = await db.query('users',
          columns: ['id', 'bookings', 'upcoming', 'spent'],
          where: 'email = ? COLLATE NOCASE', whereArgs: [email], limit: 1);
      if (rows.isEmpty) return;
      final r = rows.first;
      final bookings = ((r['bookings'] as int?) ?? 0) + bookingsDelta;
      final upcoming = ((r['upcoming'] as int?) ?? 0) + upcomingDelta;
      final spent = _parseAmount((r['spent'] ?? '').toString()) + spentDelta;
      await db.update('users', {
        'bookings': bookings < 0 ? 0 : bookings,
        'upcoming': upcoming < 0 ? 0 : upcoming,
        'spent': 'RM ${_formatAmount(spent < 0 ? 0 : spent)}',
      }, where: 'id = ?', whereArgs: [r['id']]);
    } catch (e) {
      debugPrint('Error adjusting user stats: $e');
    }
  }

  /// Parses a stored "RM 8,200" string into 8200.0.
  static double _parseAmount(String s) =>
      double.tryParse(s.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

  /// Formats a number with thousands separators, e.g. 8200 -> "8,200".
  static String _formatAmount(double value) => value.toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  // ── Booking helpers used by the booking flow ───────────────────────────────

  /// Time-slot strings already booked for a hall on a given date
  /// (anything not cancelled blocks the slot).
  Future<List<String>> getBookedSlots(String hallName, String date) async {
    try {
      final db = await _db;
      final rows = await db.query('bookings',
          columns: ['timeSlot'],
          where: 'hallName = ? AND date = ? AND status != ?',
          whereArgs: [hallName, date, 'Cancelled']);
      return rows.map((r) => (r['timeSlot'] ?? '').toString()).toList();
    } catch (e) {
      debugPrint('Error fetching booked slots: $e');
      return [];
    }
  }

  Future<bool> updateBooking(String id, Map<String, dynamic> data) async {
    try {
      final db = await _db;
      await db.update('bookings', data, where: 'id = ?', whereArgs: [id]);
      AppEvents.notifyDataChanged();
      return true;
    } catch (e) {
      debugPrint('Error updating booking: $e');
      return false;
    }
  }

  // ── Aggregate stats for dashboards ─────────────────────────────────────────

  Future<Map<String, dynamic>> getStats() async {
    try {
      final db = await _db;
      Future<int> count(String table) async =>
          Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $table')) ?? 0;

      final revenueRow = await db.rawQuery(
          "SELECT SUM(amount) AS total FROM payments WHERE status = 'Paid'");
      final revenue = (revenueRow.first['total'] as num?)?.toDouble() ?? 0.0;

      return {
        'halls': await count('halls'),
        'users': await count('users'),
        'bookings': await count('bookings'),
        'payments': await count('payments'),
        'revenue': revenue,
      };
    } catch (e) {
      debugPrint('Error computing stats: $e');
      return {'halls': 0, 'users': 0, 'bookings': 0, 'payments': 0, 'revenue': 0.0};
    }
  }

  /// Aggregations for the admin Reports & Analytics screen — all derived from
  /// the live tables so the charts always match the rest of the app.
  ///
  /// Returns:
  ///   revenueByMethod : [{method, amount}]            (Paid payments)
  ///   revenueByType   : [{type, amount}]              (Paid payments, by hall type)
  ///   topCustomers    : [{name, initials, bookings, spent}]
  ///   hallPerformance : [{name, bookings, revenue, rating, occupancy}]
  ///   monthlyRevenue  : [{label, amount}]             (up to 6 most recent months)
  ///   bookingsByDay   : [int x7]                      (Mon..Sun)
  Future<Map<String, dynamic>> getAnalytics() async {
    try {
      final db = await _db;
      final bookings = await db.query('bookings');
      final payments = await db.query('payments');
      final halls = await db.query('halls');

      bool isPaid(Map<String, Object?> p) => p['status'] == 'Paid';
      double amt(Object? v) => (v is num) ? v.toDouble() : 0.0;

      // hallName -> type, and hallName -> rating
      final typeOf = <String, String>{};
      final ratingOf = <String, double>{};
      for (final h in halls) {
        final name = (h['name'] ?? '').toString();
        typeOf[name] = (h['type'] ?? 'Other').toString();
        ratingOf[name] = amt(h['rating']);
      }

      // ── Revenue by payment method ───────────────────────────────────────────
      final byMethod = <String, double>{};
      for (final p in payments.where(isPaid)) {
        final m = (p['method'] ?? 'Other').toString();
        byMethod[m] = (byMethod[m] ?? 0) + amt(p['amount']);
      }

      // ── Revenue by hall type ────────────────────────────────────────────────
      final byType = <String, double>{};
      for (final p in payments.where(isPaid)) {
        final t = typeOf[(p['hallName'] ?? '').toString()] ?? 'Other';
        byType[t] = (byType[t] ?? 0) + amt(p['amount']);
      }

      // ── Top customers (booking count + paid spend) ─────────────────────────
      final custBookings = <String, int>{};
      for (final b in bookings) {
        final n = (b['userName'] ?? '').toString();
        if (n.isEmpty) continue;
        custBookings[n] = (custBookings[n] ?? 0) + 1;
      }
      final custSpent = <String, double>{};
      for (final p in payments.where(isPaid)) {
        final n = (p['userName'] ?? '').toString();
        if (n.isEmpty) continue;
        custSpent[n] = (custSpent[n] ?? 0) + amt(p['amount']);
      }
      final customerNames = {...custBookings.keys, ...custSpent.keys};
      final topCustomers = customerNames.map((n) => {
            'name': n,
            'initials': _initials(n),
            'bookings': custBookings[n] ?? 0,
            'spent': custSpent[n] ?? 0.0,
          }).toList()
        ..sort((a, b) => (b['spent'] as double).compareTo(a['spent'] as double));

      // ── Hall performance ────────────────────────────────────────────────────
      final hallBookings = <String, int>{};
      for (final b in bookings) {
        final n = (b['hallName'] ?? '').toString();
        if (n.isEmpty) continue;
        hallBookings[n] = (hallBookings[n] ?? 0) + 1;
      }
      final hallRevenue = <String, double>{};
      for (final p in payments.where(isPaid)) {
        final n = (p['hallName'] ?? '').toString();
        hallRevenue[n] = (hallRevenue[n] ?? 0) + amt(p['amount']);
      }
      final maxHallBookings = hallBookings.values.fold<int>(0, (m, v) => v > m ? v : m);
      final hallPerformance = halls.map((h) {
        final name = (h['name'] ?? '').toString();
        final count = hallBookings[name] ?? 0;
        return {
          'name': name,
          'bookings': count,
          'revenue': hallRevenue[name] ?? 0.0,
          'rating': ratingOf[name] ?? 0.0,
          'occupancy': maxHallBookings == 0 ? 0 : (count / maxHallBookings * 100).round(),
        };
      }).toList()
        ..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

      // ── Monthly revenue (up to 6 most recent months with paid payments) ─────
      const monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final byMonth = <String, double>{}; // key: yyyy-MM (sortable)
      for (final p in payments.where(isPaid)) {
        final ts = p['timestamp'];
        if (ts is! int) continue;
        final d = DateTime.fromMillisecondsSinceEpoch(ts);
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
        byMonth[key] = (byMonth[key] ?? 0) + amt(p['amount']);
      }
      final sortedKeys = byMonth.keys.toList()..sort();
      final recentKeys = sortedKeys.length > 6
          ? sortedKeys.sublist(sortedKeys.length - 6)
          : sortedKeys;
      final monthlyRevenue = recentKeys.map((k) {
        final month = int.parse(k.split('-')[1]);
        return {'label': monthNames[month - 1], 'amount': byMonth[k]!};
      }).toList();

      // ── Bookings by day of week (Mon..Sun) ──────────────────────────────────
      final bookingsByDay = List<int>.filled(7, 0);
      for (final b in bookings) {
        final ts = b['createdAt'];
        if (ts is! int) continue;
        final weekday = DateTime.fromMillisecondsSinceEpoch(ts).weekday; // 1=Mon..7=Sun
        bookingsByDay[weekday - 1]++;
      }

      return {
        'revenueByMethod': byMethod.entries
            .map((e) => {'method': e.key, 'amount': e.value})
            .toList()
          ..sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double)),
        'revenueByType': byType.entries
            .map((e) => {'type': e.key, 'amount': e.value})
            .toList()
          ..sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double)),
        'topCustomers': topCustomers,
        'hallPerformance': hallPerformance,
        'monthlyRevenue': monthlyRevenue,
        'bookingsByDay': bookingsByDay,
      };
    } catch (e) {
      debugPrint('Error computing analytics: $e');
      return {
        'revenueByMethod': [], 'revenueByType': [], 'topCustomers': [],
        'hallPerformance': [], 'monthlyRevenue': [], 'bookingsByDay': List<int>.filled(7, 0),
      };
    }
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  // ── Row <-> map mapping ────────────────────────────────────────────────────

  Map<String, dynamic> _hallFromRow(Map<String, Object?> r) {
    final amenities = (r['amenities'] as String?) ?? '';
    return {
      ...r,
      'id': r['id'].toString(),
      'isActive': r['isActive'] == 1,
      'imageUrl': r['image_url'],
      'amenities': amenities.isEmpty ? <String>[] : amenities.split('|'),
    };
  }

  Map<String, Object?> _hallToRow(Map<String, dynamic> data) {
    final row = <String, Object?>{};
    for (final key in [
      'name', 'type', 'location', 'capacity', 'rating', 'reviewCount',
      'price_per_day', 'price_per_hr', 'price', 'status', 'statusType',
      'description', 'image_url',
    ]) {
      if (data.containsKey(key)) row[key] = data[key];
    }
    if (data.containsKey('isActive')) {
      row['isActive'] = (data['isActive'] == true || data['isActive'] == 1) ? 1 : 0;
    }
    final amenities = data['amenities'];
    if (amenities is List) {
      row['amenities'] = amenities.join('|');
    } else if (amenities is String) {
      row['amenities'] = amenities;
    }
    return row;
  }

  Map<String, dynamic> _bookingFromRow(Map<String, Object?> r) {
    return {
      ...r,
      'id': r['id'].toString(),
      'upcoming': r['upcoming'] == 1,
    };
  }

  Future<bool> _insert(String table, Map<String, Object?> row, String label) async {
    try {
      final db = await _db;
      await db.insert(table, row);
      return true;
    } catch (e) {
      debugPrint('Error $label: $e');
      return false;
    }
  }
}
