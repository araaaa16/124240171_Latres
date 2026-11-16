import '../services/hive_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  Future<int> insertUser(Map<String, dynamic> user) async {
    return await HiveHelper.insertUser(user);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    return await HiveHelper.getUserByEmail(email);
  }

  Future<bool> emailExists(String email) async {
    return await HiveHelper.emailExists(email);
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    return await HiveHelper.getAllUsers();
  }
}
