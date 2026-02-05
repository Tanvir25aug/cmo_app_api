import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final dynamic errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T? data) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: data,
      errors: json['errors'],
    );
  }
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final _storage = const FlutterSecureStorage();
  String? _accessToken;
  String? _refreshToken;

  // Store tokens
  Future<void> setTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  // Get access token
  Future<String?> getAccessToken() async {
    _accessToken ??= await _storage.read(key: 'access_token');
    return _accessToken;
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    _refreshToken ??= await _storage.read(key: 'refresh_token');
    return _refreshToken;
  }

  // Clear tokens
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  // GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParameters,
    bool requiresAuth = true,
  }) async {
    try {
      final url = _buildUrl(endpoint, queryParameters);
      final headers = await _buildHeaders(requiresAuth);

      print('📡 GET: $url');

      final response = await http
          .get(url, headers: headers)
          .timeout(ApiConfig.connectTimeout);

      return _handleResponse<T>(response);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final url = _buildUrl(endpoint, null);
      final headers = await _buildHeaders(requiresAuth);

      print('📡 POST: $url');
      print('📤 Body: ${json.encode(body)}');

      final response = await http
          .post(
            url,
            headers: headers,
            body: json.encode(body),
          )
          .timeout(ApiConfig.sendTimeout);

      return _handleResponse<T>(response);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final url = _buildUrl(endpoint, null);
      final headers = await _buildHeaders(requiresAuth);

      print('📡 PUT: $url');

      final response = await http
          .put(
            url,
            headers: headers,
            body: json.encode(body),
          )
          .timeout(ApiConfig.sendTimeout);

      return _handleResponse<T>(response);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final url = _buildUrl(endpoint, null);
      final headers = await _buildHeaders(requiresAuth);

      print('📡 DELETE: $url');

      final response = await http
          .delete(url, headers: headers)
          .timeout(ApiConfig.connectTimeout);

      return _handleResponse<T>(response);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // Upload file
  Future<ApiResponse<T>> uploadFile<T>(
    String endpoint,
    File file,
    String fieldName, {
    Map<String, String>? additionalFields,
  }) async {
    try {
      final url = _buildUrl(endpoint, null);
      final token = await getAccessToken();

      print('📡 UPLOAD: $url');

      var request = http.MultipartRequest('POST', url);

      // Add authorization header
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(fieldName, file.path),
      );

      // Add additional fields
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final streamedResponse =
          await request.send().timeout(ApiConfig.sendTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse<T>(response);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // Build URL
  Uri _buildUrl(String endpoint, Map<String, String>? queryParameters) {
    final url = ApiConfig.buildUrl(endpoint);
    final uri = Uri.parse(url);

    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(queryParameters: queryParameters);
    }

    return uri;
  }

  // Build headers
  Future<Map<String, String>> _buildHeaders(bool requiresAuth) async {
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);

    if (requiresAuth) {
      final token = await getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Handle response
  ApiResponse<T> _handleResponse<T>(http.Response response) {
    print('📥 Response [${response.statusCode}]: ${response.body}');

    try {
      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse<T>(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'Success',
          data: jsonResponse['data'] as T?,
        );
      } else {
        return ApiResponse<T>(
          success: false,
          message: jsonResponse['message'] ?? 'Request failed',
          errors: jsonResponse['errors'],
        );
      }
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'Failed to parse response: $e',
      );
    }
  }

  // Handle errors
  ApiResponse<T> _handleError<T>(dynamic error) {
    print('❌ Error: $error');

    if (error is SocketException) {
      return ApiResponse<T>(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } else if (error is TimeoutException) {
      return ApiResponse<T>(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } else if (error is HttpException) {
      return ApiResponse<T>(
        success: false,
        message: 'Server error. Please try again later.',
      );
    } else {
      return ApiResponse<T>(
        success: false,
        message: 'An unexpected error occurred: $error',
      );
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // Refresh access token
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await post(
        ApiConfig.refreshToken,
        body: {'refreshToken': refreshToken},
        requiresAuth: false,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final newAccessToken = data['accessToken']?.toString() ?? '';
        if (newAccessToken.isEmpty) return false;
        await _storage.write(key: 'access_token', value: newAccessToken);
        _accessToken = newAccessToken;
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Token refresh failed: $e');
      return false;
    }
  }
}
