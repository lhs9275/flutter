import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import 'cwmp_api_models.dart';
import 'cwmp_session_store.dart';

class CwmpApiClient {
  CwmpApiClient({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  static const String _defaultBaseUrl = 'https://aisw.hknu.ac.kr:8443';
  static const String baseUrl = String.fromEnvironment(
    'CWMP_API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  final http.Client _http;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) async {
    final response = await _send(
      method: 'GET',
      path: path,
      query: query,
      auth: auth,
    );
    final decoded = _decodeJson(response);
    if (decoded is Map<String, dynamic>) return decoded;
    throw CwmpApiException(
      message: 'Invalid response type (expected object)',
      statusCode: response.statusCode,
      rawBody: response.body,
    );
  }

  Future<List<dynamic>> getJsonList(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) async {
    final response = await _send(
      method: 'GET',
      path: path,
      query: query,
      auth: auth,
    );
    final decoded = _decodeJson(response);
    if (decoded is List<dynamic>) return decoded;
    throw CwmpApiException(
      message: 'Invalid response type (expected list)',
      statusCode: response.statusCode,
      rawBody: response.body,
    );
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final response = await _send(
      method: 'POST',
      path: path,
      body: body == null ? null : jsonEncode(body),
      auth: auth,
      includeJsonContentType: true,
    );
    final decoded = _decodeJson(response);
    if (decoded is Map<String, dynamic>) return decoded;
    throw CwmpApiException(
      message: 'Invalid response type (expected object)',
      statusCode: response.statusCode,
      rawBody: response.body,
    );
  }

  Future<List<dynamic>> putJsonList(
    String path, {
    required Map<String, dynamic> body,
    bool auth = true,
  }) async {
    final response = await _send(
      method: 'PUT',
      path: path,
      body: jsonEncode(body),
      auth: auth,
      includeJsonContentType: true,
    );
    final decoded = _decodeJson(response);
    if (decoded is List<dynamic>) return decoded;
    throw CwmpApiException(
      message: 'Invalid response type (expected list)',
      statusCode: response.statusCode,
      rawBody: response.body,
    );
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    required Map<String, dynamic> body,
    bool auth = true,
  }) async {
    final response = await _send(
      method: 'PUT',
      path: path,
      body: jsonEncode(body),
      auth: auth,
      includeJsonContentType: true,
    );
    final decoded = _decodeJson(response);
    if (decoded is Map<String, dynamic>) return decoded;
    throw CwmpApiException(
      message: 'Invalid response type (expected object)',
      statusCode: response.statusCode,
      rawBody: response.body,
    );
  }

  Future<void> delete(String path, {bool auth = true}) async {
    await _send(method: 'DELETE', path: path, auth: auth);
  }

  Future<http.Response> _send({
    required String method,
    required String path,
    Map<String, dynamic>? query,
    String? body,
    required bool auth,
    bool includeJsonContentType = false,
    bool allowRefreshRetry = true,
  }) async {
    final uri = _buildUri(path, query);
    final response = await _sendOnce(
      method: method,
      uri: uri,
      body: body,
      auth: auth,
      includeJsonContentType: includeJsonContentType,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    final canRetryWithRefresh =
        auth && allowRefreshRetry && response.statusCode == 401;
    if (canRetryWithRefresh) {
      _debugLog(
        '401 detected for $method $path -> attempting token refresh and single retry',
      );
      await _refreshAuthTokens();
      final retryResponse = await _sendOnce(
        method: method,
        uri: uri,
        body: body,
        auth: auth,
        includeJsonContentType: includeJsonContentType,
      );
      if (retryResponse.statusCode >= 200 && retryResponse.statusCode < 300) {
        _debugLog('retry success for $method $path after refresh');
        return retryResponse;
      }
      _debugLog(
        'retry failed for $method $path after refresh (status=${retryResponse.statusCode})',
      );
      throw _buildHttpError(retryResponse);
    }

    throw _buildHttpError(response);
  }

  Future<http.Response> _sendOnce({
    required String method,
    required Uri uri,
    required String? body,
    required bool auth,
    required bool includeJsonContentType,
  }) async {
    final headers = <String, String>{};
    if (includeJsonContentType) {
      headers['Content-Type'] = 'application/json';
    }
    if (auth) {
      final token = await CwmpSessionStore.readAccessToken();
      if (token == null || token.isEmpty) {
        throw const CwmpApiException(message: '로그인이 필요합니다.', statusCode: 401);
      }
      headers['Authorization'] = 'Bearer $token';
    }
    return _performHttpRequest(
      method: method,
      uri: uri,
      headers: headers,
      body: body,
    );
  }

  Future<http.Response> _performHttpRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) async {
    try {
      switch (method) {
        case 'GET':
          return await _http.get(uri, headers: headers);
        case 'POST':
          return await _http.post(uri, headers: headers, body: body);
        case 'PUT':
          return await _http.put(uri, headers: headers, body: body);
        case 'DELETE':
          return await _http.delete(uri, headers: headers, body: body);
        default:
          throw CwmpApiException(message: 'Unsupported method: $method');
      }
    } catch (e) {
      if (e is CwmpApiException) rethrow;
      throw CwmpApiException(message: '네트워크 오류: $e');
    }
  }

  Future<void> _refreshAuthTokens() async {
    final refreshToken = await CwmpSessionStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      _debugLog('refresh skipped: no refresh token in session store');
      await CwmpSessionStore.clear();
      throw const CwmpApiException(
        message: '로그인 세션이 만료되었습니다. 다시 로그인해주세요.',
        statusCode: 401,
      );
    }

    _debugLog(
      'refresh request -> /api/auth/phone/refresh (refresh=${_previewToken(refreshToken)})',
    );

    final response = await _performHttpRequest(
      method: 'POST',
      uri: _buildUri('/api/auth/phone/refresh', null),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _debugLog(
        'refresh failed (status=${response.statusCode}, body=${_compactBodyForLog(response.body)})',
      );
      if (response.statusCode == 401) {
        await CwmpSessionStore.clear();
      }
      throw _buildHttpError(response);
    }

    final decoded = _decodeJson(response);
    if (decoded is! Map<String, dynamic>) {
      throw CwmpApiException(
        message: 'Invalid refresh response',
        statusCode: response.statusCode,
        rawBody: response.body,
      );
    }

    final tokens = CwmpAuthTokens.fromJson(decoded);
    if (tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty) {
      _debugLog('refresh failed: response missing access/refresh token');
      throw CwmpApiException(
        message: 'Invalid refresh response',
        statusCode: response.statusCode,
        rawBody: response.body,
      );
    }
    await CwmpSessionStore.updateTokens(tokens);
    _debugLog(
      'refresh success (access=${_previewToken(tokens.accessToken)}, refresh=${_previewToken(tokens.refreshToken)}, accessTtl=${tokens.accessTokenExpiresIn}, refreshTtl=${tokens.refreshTokenExpiresIn})',
    );
  }

  Uri _buildUri(String path, Map<String, dynamic>? query) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final base = Uri.parse(baseUrl);
    final queryParams = <String, String>{};
    if (query != null) {
      for (final entry in query.entries) {
        final value = entry.value;
        if (value == null) continue;
        queryParams[entry.key] = value is bool
            ? value.toString()
            : value.toString();
      }
    }
    return base.replace(
      path: normalizedPath,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
  }

  dynamic _decodeJson(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw CwmpApiException(
        message: 'Invalid JSON response',
        statusCode: response.statusCode,
        rawBody: response.body,
      );
    }
  }

  CwmpApiException _buildHttpError(http.Response response) {
    String message = '요청 실패';
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final candidates = [
            decoded['message'],
            decoded['detail'],
            decoded['error'],
          ];
          for (final candidate in candidates) {
            final text = candidate?.toString().trim() ?? '';
            if (text.isNotEmpty) {
              message = text;
              break;
            }
          }
        } else {
          final text = decoded.toString().trim();
          if (text.isNotEmpty) message = text;
        }
      } catch (_) {
        final text = response.body.trim();
        if (text.isNotEmpty) message = text;
      }
    }
    return CwmpApiException(
      message: message,
      statusCode: response.statusCode,
      rawBody: response.body,
    );
  }

  void _debugLog(String message) {
    developer.log(message, name: 'CwmpApiClient');
  }

  String _previewToken(String token) {
    if (token.isEmpty) return '<empty>';
    if (token.length <= 12) return token;
    return '${token.substring(0, 8)}...${token.substring(token.length - 6)}';
  }

  String _compactBodyForLog(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return '<empty>';
    if (trimmed.length <= 160) return trimmed;
    return '${trimmed.substring(0, 157)}...';
  }
}
