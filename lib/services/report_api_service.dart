import '../config/api_config.dart';
import 'api_client.dart';

/// Service for fetching report data from SQL Server database
/// Used by Admin Dashboard to show server-side statistics
class ReportApiService {
  static final ReportApiService instance = ReportApiService._internal();
  ReportApiService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Get complete dashboard data from SQL Server
  /// Returns all statistics in one API call for efficiency
  Future<DashboardReportResult> getDashboardData() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.reportDashboard,
      );

      if (response.success && response.data != null) {
        return DashboardReportResult(
          success: true,
          cmoStats: response.data!['cmoStats'] ?? {},
          userCount: response.data!['userCount'] ?? 0,
          customerCount: response.data!['customerCount'] ?? 0,
          topUsers: List<Map<String, dynamic>>.from(response.data!['topUsers'] ?? []),
          weeklyData: Map<String, int>.from(response.data!['weeklyData'] ?? {}),
        );
      }

      return DashboardReportResult(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return DashboardReportResult(
        success: false,
        message: 'Failed to fetch dashboard data: $e',
      );
    }
  }

  /// Get CMO statistics from SQL Server
  Future<CmoStatsResult> getCMOStatistics() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.reportCmoStats,
      );

      if (response.success && response.data != null) {
        return CmoStatsResult(
          success: true,
          stats: response.data!,
        );
      }

      return CmoStatsResult(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return CmoStatsResult(
        success: false,
        message: 'Failed to fetch CMO statistics: $e',
      );
    }
  }

  /// Get user statistics from SQL Server
  Future<UserStatsResult> getUserStatistics() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.reportUserStats,
      );

      if (response.success && response.data != null) {
        return UserStatsResult(
          success: true,
          userCount: response.data!['userCount'] ?? 0,
        );
      }

      return UserStatsResult(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return UserStatsResult(
        success: false,
        message: 'Failed to fetch user statistics: $e',
      );
    }
  }

  /// Get top users by CMO count from SQL Server
  Future<TopUsersResult> getTopUsersByCMOCount({int limit = 5}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.reportTopUsers,
        queryParameters: {'limit': limit.toString()},
      );

      if (response.success && response.data != null) {
        final users = response.data!['users'];
        return TopUsersResult(
          success: true,
          users: users is List
              ? List<Map<String, dynamic>>.from(users)
              : [],
        );
      }

      return TopUsersResult(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return TopUsersResult(
        success: false,
        message: 'Failed to fetch top users: $e',
      );
    }
  }

  /// Get weekly CMO data from SQL Server
  Future<WeeklyDataResult> getWeeklyData() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.reportWeeklyData,
      );

      if (response.success && response.data != null) {
        final weeklyData = response.data!['weeklyData'];
        return WeeklyDataResult(
          success: true,
          data: weeklyData is Map
              ? Map<String, int>.from(weeklyData.map((k, v) => MapEntry(k.toString(), v is int ? v : int.tryParse(v.toString()) ?? 0)))
              : {},
        );
      }

      return WeeklyDataResult(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return WeeklyDataResult(
        success: false,
        message: 'Failed to fetch weekly data: $e',
      );
    }
  }

  /// Get customer count from SQL Server
  Future<CustomerCountResult> getCustomerCount() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.reportCustomerCount,
      );

      if (response.success && response.data != null) {
        return CustomerCountResult(
          success: true,
          count: response.data!['count'] ?? 0,
        );
      }

      return CustomerCountResult(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return CustomerCountResult(
        success: false,
        message: 'Failed to fetch customer count: $e',
      );
    }
  }
}

/// Result class for complete dashboard data
class DashboardReportResult {
  final bool success;
  final String? message;
  final Map<String, dynamic> cmoStats;
  final int userCount;
  final int customerCount;
  final List<Map<String, dynamic>> topUsers;
  final Map<String, int> weeklyData;

  DashboardReportResult({
    required this.success,
    this.message,
    this.cmoStats = const {},
    this.userCount = 0,
    this.customerCount = 0,
    this.topUsers = const [],
    this.weeklyData = const {},
  });
}

/// Result class for CMO statistics
class CmoStatsResult {
  final bool success;
  final String? message;
  final Map<String, dynamic> stats;

  CmoStatsResult({
    required this.success,
    this.message,
    this.stats = const {},
  });
}

/// Result class for user statistics
class UserStatsResult {
  final bool success;
  final String? message;
  final int userCount;

  UserStatsResult({
    required this.success,
    this.message,
    this.userCount = 0,
  });
}

/// Result class for top users
class TopUsersResult {
  final bool success;
  final String? message;
  final List<Map<String, dynamic>> users;

  TopUsersResult({
    required this.success,
    this.message,
    this.users = const [],
  });
}

/// Result class for weekly data
class WeeklyDataResult {
  final bool success;
  final String? message;
  final Map<String, int> data;

  WeeklyDataResult({
    required this.success,
    this.message,
    this.data = const {},
  });
}

/// Result class for customer count
class CustomerCountResult {
  final bool success;
  final String? message;
  final int count;

  CustomerCountResult({
    required this.success,
    this.message,
    this.count = 0,
  });
}
