import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/report_api_service.dart';
import '../../utils/app_theme.dart';
import 'user_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic> _cmoStats = {};
  int _userCount = 0;
  int _customerCount = 0;
  List<Map<String, dynamic>> _topUsers = [];
  Map<String, int> _weeklyData = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Fetch all data from SQL Server via API
      final result = await ReportApiService.instance.getDashboardData();

      if (result.success) {
        if (mounted) {
          setState(() {
            _cmoStats = result.cmoStats;
            _userCount = result.userCount;
            _customerCount = result.customerCount;
            _topUsers = result.topUsers;
            _weeklyData = result.weeklyData;
            _isLoading = false;
          });
        }
      } else {
        // If dashboard endpoint fails, try individual endpoints
        await _loadDataIndividually();
      }
    } catch (e) {
      // Fallback to individual endpoints on error
      await _loadDataIndividually();
    }
  }

  /// Fallback method to load data from individual API endpoints
  Future<void> _loadDataIndividually() async {
    try {
      // Fetch CMO statistics
      final cmoResult = await ReportApiService.instance.getCMOStatistics();
      if (cmoResult.success) {
        _cmoStats = cmoResult.stats;
      }

      // Fetch user count
      final userResult = await ReportApiService.instance.getUserStatistics();
      if (userResult.success) {
        _userCount = userResult.userCount;
      }

      // Fetch customer count
      final customerResult = await ReportApiService.instance.getCustomerCount();
      if (customerResult.success) {
        _customerCount = customerResult.count;
      }

      // Fetch top users
      final topUsersResult = await ReportApiService.instance.getTopUsersByCMOCount(limit: 5);
      if (topUsersResult.success) {
        _topUsers = topUsersResult.users;
      }

      // Fetch weekly data
      final weeklyResult = await ReportApiService.instance.getWeeklyData();
      if (weeklyResult.success) {
        _weeklyData = weeklyResult.data;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          // Check if we got any data
          if (_cmoStats.isEmpty && _userCount == 0 && _customerCount == 0) {
            _hasError = true;
            _errorMessage = 'Unable to fetch data from server. Please check your connection.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to load data: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // Check if user is admin
    if (!authService.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 80, color: AppTheme.errorColor),
              SizedBox(height: 16),
              Text(
                'Admin Access Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('You do not have permission to view this page.'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 140,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF6C63FF),
                          Color(0xFF3F3D56),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'Admin Dashboard',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.cloud, color: Colors.white70, size: 16),
                              const SizedBox(width: 6),
                              const Text(
                                'Server Data - SQL Server Reports',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadDashboardData,
                  ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(50),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _hasError
                        ? _buildErrorWidget()
                        : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Quick Actions
                            _buildSectionTitle('Quick Actions'),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _QuickActionCard(
                                    icon: Icons.people,
                                    label: 'User Management',
                                    color: AppTheme.primaryColor,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const UserManagementScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _QuickActionCard(
                                    icon: Icons.analytics,
                                    label: 'View Reports',
                                    color: AppTheme.secondaryColor,
                                    onTap: () {
                                      _showReportsBottomSheet();
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Overview Stats
                            Row(
                              children: [
                                _buildSectionTitle('Overview'),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.cloud, size: 12, color: AppTheme.successColor),
                                      SizedBox(width: 4),
                                      Text(
                                        'SQL Server',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.successColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.description,
                                    title: 'Total CMOs',
                                    value: '${_cmoStats['total'] ?? 0}',
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.people,
                                    title: 'Users',
                                    value: '$_userCount',
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.person,
                                    title: 'Customers',
                                    value: '$_customerCount',
                                    color: Colors.teal,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.location_on,
                                    title: 'With GPS',
                                    value: '${_cmoStats['withLocation'] ?? 0}',
                                    color: AppTheme.successColor,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // CMO Status Distribution
                            _buildSectionTitle('CMO Status Distribution'),
                            const SizedBox(height: 12),
                            _buildStatusDistribution(),

                            const SizedBox(height: 24),

                            // Time-based Reports
                            _buildSectionTitle('CMO Activity'),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _TimeStatCard(
                                    title: 'Today',
                                    value: '${_cmoStats['today'] ?? 0}',
                                    icon: Icons.today,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _TimeStatCard(
                                    title: 'This Week',
                                    value: '${_cmoStats['thisWeek'] ?? 0}',
                                    icon: Icons.date_range,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _TimeStatCard(
                                    title: 'This Month',
                                    value: '${_cmoStats['thisMonth'] ?? 0}',
                                    icon: Icons.calendar_month,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Weekly Chart
                            _buildSectionTitle('Last 7 Days'),
                            const SizedBox(height: 12),
                            _buildWeeklyChart(),

                            const SizedBox(height: 24),

                            // Top Users
                            if (_topUsers.isNotEmpty) ...[
                              _buildSectionTitle('Top Contributors'),
                              const SizedBox(height: 12),
                              _buildTopUsersList(),
                            ],

                            const SizedBox(height: 24),

                            // Sync Status
                            _buildSectionTitle('Sync Status'),
                            const SizedBox(height: 12),
                            _buildSyncStatus(),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off,
              size: 80,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to Load Server Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildStatusDistribution() {
    final total = _cmoStats['total'] ?? 1;
    final draft = _cmoStats['draft'] ?? 0;
    final pending = _cmoStats['pending'] ?? 0;
    final uploaded = _cmoStats['uploaded'] ?? 0;
    final synced = _cmoStats['synced'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 24,
                child: Row(
                  children: [
                    if (draft > 0)
                      Expanded(
                        flex: draft,
                        child: Container(color: AppTheme.textSecondary),
                      ),
                    if (pending > 0)
                      Expanded(
                        flex: pending,
                        child: Container(color: AppTheme.warningColor),
                      ),
                    if (uploaded > 0)
                      Expanded(
                        flex: uploaded,
                        child: Container(color: Colors.blue),
                      ),
                    if (synced > 0)
                      Expanded(
                        flex: synced,
                        child: Container(color: AppTheme.successColor),
                      ),
                    if (total == 0)
                      Expanded(child: Container(color: Colors.grey[300])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LegendItem(
                  color: AppTheme.textSecondary,
                  label: 'Draft',
                  value: draft,
                ),
                _LegendItem(
                  color: AppTheme.warningColor,
                  label: 'Pending',
                  value: pending,
                ),
                _LegendItem(
                  color: Colors.blue,
                  label: 'Uploaded',
                  value: uploaded,
                ),
                _LegendItem(
                  color: AppTheme.successColor,
                  label: 'Synced',
                  value: synced,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final dateFormat = DateFormat('E');
    final now = DateTime.now();

    // Generate last 7 days
    List<MapEntry<String, int>> dailyData = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      dailyData.add(MapEntry(dateStr, _weeklyData[dateStr] ?? 0));
    }

    final maxValue = dailyData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final chartMax = maxValue > 0 ? maxValue : 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: dailyData.map((entry) {
                  final date = DateTime.parse(entry.key);
                  final height = (entry.value / chartMax) * 120;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${entry.value}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: height > 0 ? height : 4,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dateFormat.format(date),
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopUsersList() {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _topUsers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = _topUsers[index];
          final rank = index + 1;
          Color rankColor;
          switch (rank) {
            case 1:
              rankColor = Colors.amber;
              break;
            case 2:
              rankColor = Colors.grey;
              break;
            case 3:
              rankColor = Colors.brown;
              break;
            default:
              rankColor = AppTheme.textSecondary;
          }

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: rankColor.withValues(alpha: 0.2),
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                ),
              ),
            ),
            title: Text(user['fullName']?.toString() ?? user['username']?.toString() ?? 'Unknown'),
            subtitle: Text('@${user['username']?.toString() ?? 'N/A'}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${user['cmo_count']?.toString() ?? '0'} CMOs',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSyncStatus() {
    final total = _cmoStats['total'] ?? 0;
    final synced = _cmoStats['synced'] ?? 0;
    final unsynced = total - synced;
    final syncPercent = total > 0 ? (synced / total * 100).toStringAsFixed(1) : '0';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$syncPercent% Synced',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total > 0 ? synced / total : 0,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation(AppTheme.successColor),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$synced synced, $unsynced pending',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              unsynced > 0 ? Icons.sync_problem : Icons.cloud_done,
              size: 48,
              color: unsynced > 0 ? AppTheme.warningColor : AppTheme.successColor,
            ),
          ],
        ),
      ),
    );
  }

  void _showReportsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Available Reports',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.successColor),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud, size: 14, color: AppTheme.successColor),
                        SizedBox(width: 4),
                        Text(
                          'Server',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'All reports are generated from SQL Server database',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              _ReportOption(
                icon: Icons.bar_chart,
                title: 'CMO Summary Report',
                subtitle: 'Overview of all CMO requests by status',
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog('CMO Summary', _buildCMOSummaryReport());
                },
              ),
              _ReportOption(
                icon: Icons.people,
                title: 'User Activity Report',
                subtitle: 'CMO submissions by user',
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog('User Activity', _buildUserActivityReport());
                },
              ),
              _ReportOption(
                icon: Icons.calendar_today,
                title: 'Daily Report',
                subtitle: 'CMOs created today',
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog('Daily Report', _buildDailyReport());
                },
              ),
              _ReportOption(
                icon: Icons.sync,
                title: 'Sync Status Report',
                subtitle: 'Pending synchronization summary',
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog('Sync Status', _buildSyncReport());
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showReportDialog(String title, Widget content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildCMOSummaryReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReportRow('Total CMOs', '${_cmoStats['total'] ?? 0}'),
        _ReportRow('Draft', '${_cmoStats['draft'] ?? 0}'),
        _ReportRow('Pending', '${_cmoStats['pending'] ?? 0}'),
        _ReportRow('Uploaded', '${_cmoStats['uploaded'] ?? 0}'),
        _ReportRow('Synced', '${_cmoStats['synced'] ?? 0}'),
        const Divider(),
        _ReportRow('With GPS Location', '${_cmoStats['withLocation'] ?? 0}'),
      ],
    );
  }

  Widget _buildUserActivityReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top $_userCount users by CMO count:'),
        const SizedBox(height: 8),
        ..._topUsers.map((user) => _ReportRow(
          user['fullName']?.toString() ?? user['username']?.toString() ?? 'Unknown',
          '${user['cmo_count']?.toString() ?? '0'} CMOs',
        )),
      ],
    );
  }

  Widget _buildDailyReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReportRow('Today\'s CMOs', '${_cmoStats['today'] ?? 0}'),
        _ReportRow('This Week', '${_cmoStats['thisWeek'] ?? 0}'),
        _ReportRow('This Month', '${_cmoStats['thisMonth'] ?? 0}'),
      ],
    );
  }

  Widget _buildSyncReport() {
    final total = _cmoStats['total'] ?? 0;
    final synced = _cmoStats['synced'] ?? 0;
    final unsynced = total - synced;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReportRow('Total Synced', '$synced'),
        _ReportRow('Pending Sync', '$unsynced'),
        _ReportRow('Sync Rate', total > 0 ? '${(synced / total * 100).toStringAsFixed(1)}%' : '0%'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _TimeStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$value',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ReportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ReportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReportRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
