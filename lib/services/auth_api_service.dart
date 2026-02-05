import '../config/api_config.dart';
import 'api_client.dart';

class AuthApiService {
  final ApiClient _apiClient = ApiClient();

  // Login with email and password
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.login,
        body: {
          'email': email,
          'password': password,
        },
        requiresAuth: false,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        // Store tokens (use toString() to handle type variations)
        final accessToken = data['accessToken']?.toString() ?? '';
        final refreshToken = data['refreshToken']?.toString() ?? '';
        await _apiClient.setTokens(accessToken, refreshToken);

        // Return user data
        return data['user'] as Map<String, dynamic>?;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      print('❌ Login error: $e');
      rethrow;
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await _apiClient.get(
        ApiConfig.profile,
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      print('❌ Get profile error: $e');
      rethrow;
    }
  }

  // Update profile
  Future<Map<String, dynamic>?> updateProfile(
      Map<String, dynamic> updates) async {
    try {
      final response = await _apiClient.put(
        ApiConfig.updateProfile,
        body: updates,
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      print('❌ Update profile error: $e');
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      // Call logout endpoint (optional - since JWT is stateless)
      await _apiClient.post(
        ApiConfig.logout,
        requiresAuth: true,
      );
    } catch (e) {
      print('❌ Logout error: $e');
    } finally {
      // Clear tokens locally
      await _apiClient.clearTokens();
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _apiClient.isAuthenticated();
  }

  // Refresh token
  Future<bool> refreshToken() async {
    return await _apiClient.refreshAccessToken();
  }

  // Check API connection
  Future<bool> checkApiConnection() async {
    try {
      final response = await _apiClient.get(
        ApiConfig.health,
        requiresAuth: false,
      );

      return response.success;
    } catch (e) {
      print('❌ API connection check failed: $e');
      return false;
    }
  }
}
