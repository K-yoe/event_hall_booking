import 'package:shared_preferences/shared_preferences.dart';
import 'db_service.dart';

/// Holds the currently logged-in user for the whole app.
///
/// Backed by the SQLite `users` table (via [DbService]) and persisted across
/// restarts with shared_preferences (just the email; the row is reloaded).
class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  static const _prefsKey = 'current_user_email';

  final DbService _db = DbService();
  Map<String, dynamic>? currentUser;

  bool get isLoggedIn => currentUser != null;
  bool get isAdmin => (currentUser?['role'] ?? 'user') == 'admin';

  String get name => (currentUser?['name'] ?? 'Guest').toString();
  String get email => (currentUser?['email'] ?? '').toString();
  String get initials => (currentUser?['initials'] ?? _initialsFrom(name)).toString();

  /// Re-load the session from prefs on app start (if any).
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_prefsKey);
    if (email == null) return;
    if (email.contains('admin')) {
      currentUser = _adminUser(email);
    } else {
      currentUser = await _db.getUserByEmail(email) ?? _guestUser(email);
    }
  }

  /// Demo login: admins by email keyword, otherwise look up / accept the user.
  /// (No password checking — this is a demo app.)
  Future<Map<String, dynamic>> login(String email, String password) async {
    email = email.trim().toLowerCase();
    if (email.contains('admin')) {
      currentUser = _adminUser(email);
    } else {
      currentUser = await _db.getUserByEmail(email) ?? _guestUser(email);
    }
    await _persist(email);
    return currentUser!;
  }

  /// Register a new user: insert into the users table and sign in.
  Future<Map<String, dynamic>> register(
      String name, String email, String phone) async {
    name = name.trim();
    email = email.trim().toLowerCase();
    final initials = _initialsFrom(name);
    final row = {
      'name': name,
      'email': email,
      'phone': phone.trim(),
      'role': 'user',
      'bookings': 0,
      'spent': 'RM 0',
      'upcoming': 0,
      'status': 'Active',
      'initials': initials,
      'avatarColor': 0xFFE6F1FB,
      'textColor': 0xFF0C447C,
      'joined': _today(),
    };
    await _db.addUser(row);
    currentUser = await _db.getUserByEmail(email) ?? row;
    await _persist(email);
    return currentUser!;
  }

  Future<void> logout() async {
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  Future<void> _persist(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, email);
  }

  Map<String, dynamic> _adminUser(String email) => {
        'id': 'admin',
        'name': 'Administrator',
        'email': email,
        'phone': '-',
        'role': 'admin',
        'initials': 'AD',
        'avatarColor': 0xFFFAC775,
        'textColor': 0xFF633806,
        'joined': _today(),
      };

  Map<String, dynamic> _guestUser(String email) => {
        'id': '',
        'name': _nameFromEmail(email),
        'email': email,
        'phone': '-',
        'role': 'user',
        'initials': _initialsFrom(_nameFromEmail(email)),
        'avatarColor': 0xFFE6F1FB,
        'textColor': 0xFF0C447C,
        'joined': _today(),
      };

  static String _nameFromEmail(String email) {
    final local = email.split('@').first.replaceAll(RegExp(r'[._]'), ' ').trim();
    if (local.isEmpty) return 'Guest';
    return local
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static String _initialsFrom(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  static String _today() {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final now = DateTime.now();
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}
