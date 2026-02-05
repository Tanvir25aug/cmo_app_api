import '../config/api_config.dart';
import 'api_client.dart';

class UserApiService {
  static final UserApiService _instance = UserApiService._internal();
  static UserApiService get instance => _instance;

  final ApiClient _apiClient = ApiClient();

  UserApiService._internal();

  // Get all users (admin only)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _apiClient.get(
        '/auth/users',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data as List);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      print('Get all users error: $e');
      rethrow;
    }
  }

  // Create new user (admin only)
  Future<Map<String, dynamic>> createUser({
    required String username,
    required String password,
    String? userId,
    String role = 'user',
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/users',
        body: {
          'username': username,
          'password': password,
          'userId': userId ?? username,
          'role': role,
        },
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      print('Create user error: $e');
      rethrow;
    }
  }

  // Update user (admin only)
  Future<Map<String, dynamic>> updateUser({
    required int securityId,
    String? username,
    String? userId,
    String? role,
    String? password,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (username != null) body['UserName'] = username;
      if (userId != null) body['UserId'] = userId;
      if (role != null) body['role'] = role;
      if (password != null) body['UserPwd'] = password;

      final response = await _apiClient.put(
        '/auth/users/$securityId',
        body: body,
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      print('Update user error: $e');
      rethrow;
    }
  }

  // Delete user (admin only)
  Future<bool> deleteUser(int securityId) async {
    try {
      final response = await _apiClient.delete(
        '/auth/users/$securityId',
        requiresAuth: true,
      );

      if (response.success) {
        return true;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      print('Delete user error: $e');
      rethrow;
    }
  }
}
