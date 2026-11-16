import 'package:shared_preferences/shared_preferences.dart';
import 'hive_helper.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';

  Future<String?> register(String name, String email, String password) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanName.isEmpty) return 'Name cannot be empty';
    if (cleanEmail.isEmpty) return 'Email cannot be empty';
    if (!_isValidEmail(cleanEmail)) return 'Invalid email format';
    if (password.length < 6) return 'Password must be at least 6 characters';

    final exists = await HiveHelper.emailExists(cleanEmail);
    if (exists) return 'Email already registered';

    await HiveHelper.insertUser({
      'name': cleanName,
      'email': cleanEmail,
      'password': password,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return null;
  }

  Future<String?> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty) return 'Email cannot be empty';
    if (password.isEmpty) return 'Password cannot be empty';
    if (!_isValidEmail(cleanEmail)) return 'Invalid email format';

    final user = await HiveHelper.getUserByEmail(cleanEmail);
    if (user == null) return 'Email not registered';
    if (user['password'] != password) return 'Incorrect password';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserEmail, user['email'] as String);
    await prefs.setString(_keyUserName, user['name'] as String);
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserName);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
