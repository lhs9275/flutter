import 'package:shared_preferences/shared_preferences.dart';

import 'cwmp_api_models.dart';

class CwmpSessionStore {
  static const _kAccessToken = 'cwmp_access_token';
  static const _kRefreshToken = 'cwmp_refresh_token';
  static const _kTokenType = 'cwmp_token_type';
  static const _kUserId = 'cwmp_user_id';
  static const _kPhoneNumber = 'cwmp_phone_number';
  static const _kUserName = 'cwmp_user_name';
  static const _kUserRole = 'cwmp_user_role';

  static Future<void> saveLogin(CwmpPhoneAuthLoginResponse login) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessToken, login.tokens.accessToken);
    await prefs.setString(_kRefreshToken, login.tokens.refreshToken);
    await prefs.setString(_kTokenType, login.tokens.tokenType);
    await prefs.setInt(_kUserId, login.user.id);
    await prefs.setString(_kPhoneNumber, login.user.phoneNumber);
    await prefs.setString(_kUserRole, login.user.role.apiValue);
    final name = login.user.name?.trim();
    if (name != null && name.isNotEmpty) {
      await prefs.setString(_kUserName, name);
    } else {
      await prefs.remove(_kUserName);
    }
  }

  static Future<CwmpSessionSnapshot?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_kAccessToken) ?? '';
    final refreshToken = prefs.getString(_kRefreshToken) ?? '';
    if (accessToken.isEmpty) return null;
    return CwmpSessionSnapshot(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: prefs.getString(_kTokenType) ?? 'Bearer',
      userId: prefs.getInt(_kUserId) ?? 0,
      phoneNumber: prefs.getString(_kPhoneNumber) ?? '',
      role: CwmpUserRoleX.fromApi(prefs.getString(_kUserRole) ?? 'WORKER'),
      name: prefs.getString(_kUserName),
    );
  }

  static Future<String?> readAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kAccessToken);
    if (token == null || token.isEmpty) return null;
    return token;
  }

  static Future<String?> readRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kRefreshToken);
    if (token == null || token.isEmpty) return null;
    return token;
  }

  static Future<void> updateTokens(CwmpAuthTokens tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessToken, tokens.accessToken);
    await prefs.setString(_kRefreshToken, tokens.refreshToken);
    await prefs.setString(_kTokenType, tokens.tokenType);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kRefreshToken);
    await prefs.remove(_kTokenType);
    await prefs.remove(_kUserId);
    await prefs.remove(_kPhoneNumber);
    await prefs.remove(_kUserName);
    await prefs.remove(_kUserRole);
  }
}
