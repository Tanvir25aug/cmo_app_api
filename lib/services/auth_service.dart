import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService extends ChangeNotifier {
  // Singleton instance for non-widget access
  static AuthService? _instance;
  static AuthService get instance {
    _instance ??= AuthService();
    return _instance!;
  }

  // Set instance (called from Provider initialization)
  static void setInstance(AuthService service) {
    _instance = service;
  }

  User? _currentUser;
  bool _isAuthenticated = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _currentUser?.role?.toLowerCase() == 'admin';

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final userName = prefs.getString('userName');

    if (userId != null) {
      // First try to get from local database
      _currentUser = await DatabaseService.instance.getUserById(userId);

      // If not found in DB but we have stored username (API login), create user object
      if (_currentUser == null && userName != null) {
        _currentUser = User(
          id: userId,
          username: userName,
          email: prefs.getString('userEmail') ?? '',
          fullName: userName,
          role: prefs.getString('userRole') ?? 'user',
          createdAt: DateTime.now(),
        );
      }

      _isAuthenticated = _currentUser != null;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    try {
      final user = User(
        username: username,
        email: email,
        fullName: fullName,
        phone: phone,
        role: 'user',
        createdAt: DateTime.now(),
      );

      final userId = await DatabaseService.instance.createUser(user, password);

      if (userId != null) {
        // Auto-login after registration
        return await login(username: username, password: password);
      }
      return false;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    try {
      final user = await DatabaseService.instance.loginUser(username, password);

      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', user.id!);

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // Login with API data (for API authentication)
  // API returns data from AdminSecurity table: {SecurityId, UserId, UserName}
  Future<bool> loginWithApiData(Map<String, dynamic> userData) async {
    try {
      // Extract required fields with fallbacks
      // API may return: {id, userId, username, UserName, userName} - handle all cases
      // Use .toString() to handle int/String type variations from API
      final id = userData['id']?.toString() ??
          userData['SecurityId']?.toString() ??
          '';

      // Get username - try multiple possible field names
      final username = userData['username']?.toString() ??
          userData['UserName']?.toString() ??
          userData['userName']?.toString() ??
          userData['userId']?.toString() ??
          userData['UserId']?.toString() ??
          '';

      // Get role - API returns 'role' field
      final role = userData['role']?.toString() ??
          userData['Rrole']?.toString() ??
          userData['Role']?.toString() ??
          'user';

      // Create user object from API data
      final user = User(
        id: id,
        username: username,
        email: userData['email']?.toString() ?? '',
        fullName: username, // Use username as display name
        phone: userData['phone']?.toString(),
        role: role.toLowerCase(),
        createdAt: DateTime.now(),
      );

      _currentUser = user;
      _isAuthenticated = true;

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', user.id ?? user.username);
      await prefs.setString('userEmail', user.email ?? '');
      await prefs.setString('userName', user.username);
      await prefs.setString('userRole', user.role ?? 'user'); // Save role for admin check

      notifyListeners();
      return true;
    } catch (e) {
      print('Login with API data error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userEmail');
    await prefs.remove('userName');
    await prefs.remove('userRole');

    notifyListeners();
  }

  Future<void> updateProfile(User updatedUser) async {
    _currentUser = updatedUser;
    notifyListeners();
  }
}
