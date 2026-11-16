import 'package:hive_flutter/hive_flutter.dart';

class HiveHelper {
  static const String usersBoxName = 'users_box';
  static bool _initialized = false;

  /// Initialize Hive and open necessary boxes.
  static Future<void> init() async {
    if (!_initialized) {
      await Hive.initFlutter();
      await Hive.openBox<Map>(usersBoxName);
      _initialized = true;
    }
  }

  static Box<Map> get usersBox => Hive.box<Map>(usersBoxName);

  /// Insert or update a registered user in Hive.
  static Future<int> insertUser(Map<String, dynamic> user) async {
    final box = usersBox;
    final email = (user['email'] as String).trim().toLowerCase();
    await box.put(email, Map<String, dynamic>.from(user));
    return box.length;
  }

  /// Retrieve a registered user by email from Hive.
  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final box = usersBox;
    final data = box.get(email.trim().toLowerCase());
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  /// Check whether an email is already registered in Hive.
  static Future<bool> emailExists(String email) async {
    final box = usersBox;
    return box.containsKey(email.trim().toLowerCase());
  }

  /// Get all registered users from Hive.
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final box = usersBox;
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}

