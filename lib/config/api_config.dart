class ApiConfig {
  // API Base URL - Update this with your server IP address
  // For testing on emulator: use 10.0.2.2 (Android) or localhost (iOS)
  // For testing on real device: use your computer's IP address
  static const String baseUrl = 'http://103.37.202.8:8085'; // WiFi IP - change to VPN IP (172.18.31.19) if needed

  static const String apiPrefix = '/api';
  static const String apiBaseUrl = '$baseUrl$apiPrefix';

  // Authentication Endpoints
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh-token';
  static const String profile = '/auth/profile';
  static const String updateProfile = '/auth/profile';
  static const String logout = '/auth/logout';

  // CMO Endpoints
  static const String cmoList = '/cmo';
  static const String cmoCreate = '/cmo';
  static const String cmoUpdate = '/cmo'; // + /:id
  static const String cmoDelete = '/cmo'; // + /:id
  static const String cmoSync = '/cmo/sync';
  static const String cmoStatistics = '/cmo/statistics';

  // Report Endpoints (Admin Dashboard - from SQL Server)
  static const String reportDashboard = '/reports/dashboard';
  static const String reportCmoStats = '/reports/cmo-statistics';
  static const String reportUserStats = '/reports/user-statistics';
  static const String reportTopUsers = '/reports/top-users';
  static const String reportWeeklyData = '/reports/weekly-data';
  static const String reportCustomerCount = '/reports/customer-count';

  // Customer Endpoints
  static const String customerById = '/customer'; // + /:id
  static const String customerMeterInfoCheck = '/customer'; // + /:id/meter-info-check
  static const String customersSync = '/customers/sync';
  static const String customersCount = '/customers/count';

  // File Upload
  // Images are uploaded to D:\Node_API\cmo-api-package\uploads\{folder}\
  static const String uploadMeters = '/upload/meters';  // -> uploads/meters/
  static const String uploadSeals = '/upload/seals';    // -> uploads/seals/

  // Health Check
  static const String health = '/health';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Headers
  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Map<String, String> authHeaders(String token) => {
        ...defaultHeaders,
        'Authorization': 'Bearer $token',
      };

  // Helper to build full URL
  static String buildUrl(String endpoint) {
    return '$apiBaseUrl$endpoint';
  }

  // Check if using local development
  static bool get isLocalDevelopment =>
      baseUrl.contains('localhost') ||
      baseUrl.contains('127.0.0.1') ||
      baseUrl.contains('10.0.2.2');
}
