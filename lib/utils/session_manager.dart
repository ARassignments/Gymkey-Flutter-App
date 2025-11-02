import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../notifiers/avatar_notifier.dart';

class SessionManager {
  static const String _userTokenKey = "USER_TOKEN";
  static const String _userKey = "USER";
  static const String _rememberMeKey = "REMEMBER_ME";
  static const String _organizationIdKey = "ORGANIZATION_ID";

  static const String _avatarKey = "USER_AVATAR";
  static const String _genderKey = "USER_GENDER";

  /// Save user session
  static Future<void> saveUserSession(
    String token,
    Map<String, dynamic> user,
    bool rememberMe,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userTokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
    await prefs.setBool(_rememberMeKey, rememberMe);

    if (user.containsKey("OrganizationId") && user["OrganizationId"] != null) {
      await prefs.setInt(_organizationIdKey, user["OrganizationId"]);
    }
  }

  /// Save avatar + gender (independent of API session)
  static Future<void> saveAvatarAndGender(String gender, String avatarPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarKey, avatarPath);
    await prefs.setString(_genderKey, gender);
    avatarNotifier.updateAvatar(avatarPath);
  }

  /// Get avatar + gender
  static Future<Map<String, String?>> getAvatarAndGender() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "gender": prefs.getString(_genderKey),
      "avatar": prefs.getString(_avatarKey),
    };
  }

  /// Get user token
  static Future<String?> getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTokenKey);
  }

  /// Get user object
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    if (userString != null) {
      return jsonDecode(userString);
    }
    return null;
  }

  /// Get remember me flag
  static Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  /// Get organization id
  static Future<int?> getOrganizationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_organizationIdKey);
  }

  /// Clear session
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userTokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_rememberMeKey);
    await prefs.remove(_organizationIdKey);
    await prefs.remove(_avatarKey);
    await prefs.remove(_genderKey);
  }
}
