import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyDbId = 'db_id';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserCode = 'user_code';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserPhone = 'user_phone';
  static const String _keyIsLoggedIn = 'is_logged_in';

  /// Save user data after login
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Try to get ID from 'id' field first, then 'db_id' field
    final id = userData['id'] ?? userData['db_id'];
    
    await prefs.setInt(
      _keyDbId,
      id is int
          ? id
          : int.tryParse('$id') ?? 0,
    );
    await prefs.setString(_keyUserId, '${userData['user_id'] ?? ''}');
    await prefs.setString(_keyUserName, '${userData['name'] ?? ''}');
    await prefs.setString(_keyUserCode, '${userData['code'] ?? ''}');
    await prefs.setString(_keyUserEmail, '${userData['email'] ?? ''}');
    await prefs.setString(_keyUserPhone, '${userData['phone'] ?? ''}');
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  /// Get database ID
  static Future<int?> getDbId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDbId);
  }

  /// Get technician ID (same as db_id)
  static Future<int?> getTechnicianId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDbId);
  }

  /// Get user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  /// Get user name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  /// Get user code
  static Future<String?> getUserCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserCode);
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Get all user data
  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'db_id': prefs.getInt(_keyDbId),
      'user_id': prefs.getString(_keyUserId),
      'name': prefs.getString(_keyUserName),
      'code': prefs.getString(_keyUserCode),
      'email': prefs.getString(_keyUserEmail),
      'phone': prefs.getString(_keyUserPhone),
    };
  }
}
