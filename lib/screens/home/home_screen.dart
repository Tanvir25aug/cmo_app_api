import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/cmo_model.dart';
import '../../utils/app_theme.dart';
import '../settings/settings_screen.dart';
import '../cmo/cmo_screen.dart';
import '../cmo/add_cmo_screen.dart';
import '../cmo/bulk_cmo_start_screen.dart';
import '../map/map_screen.dart';
import '../../widgets/stat_card.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CMO> _cmoList = [];
  bool _isLoading = true;
  int _draftCount = 0;
  int _unsyncedCount = 0;
  int _syncedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final cmos = await DatabaseService.instance.getAllCMOs();
      final unsyncedCount = await DatabaseService.instance.getUploadedUnsyncedCount();
      final syncedCount = await DatabaseService.instance.getSyncedCMOsCount();

      if (mounted) {
        setState(() {
          _cmoList = cmos;
          _draftCount = cmos.where((c) => c.status == 'draft').length;
          _unsyncedCount = unsyncedCount;
          _syncedCount = syncedCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.secondaryColor,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Hello, ${authService.currentUser?.fullName ?? authService.currentUser?.username ?? "User"}!',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Manage Change Meter Order Requests',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statistics Cards
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              icon: Icons.description,
                              title: 'Total CMOs',
                              value: '${_cmoList.length}',
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              icon: Icons.drafts,
                              title: 'Draft',
                              value: '$_draftCount',
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              icon: Icons.cloud_upload,
                              title: 'Unsynced',
                              value: '$_unsyncedCount',
                              color: AppTheme.warningColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              icon: Icons.cloud_done,
                              title: 'Synced',
                              value: '$_syncedCount',
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Quick Actions
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.add_circle_outline,
                              label: 'New CMO',
                              color: AppTheme.primaryColor,
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const AddCMOScreen()),
                                );
                                _loadData();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.list_alt,
                              label: 'All CMOs',
                              color: AppTheme.secondaryColor,
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const CMOScreen()),
                                );
                                _loadData();
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Map View and Bulk CMO Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.map_outlined,
                              label: 'Map View',
                              color: AppTheme.successColor,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const MapScreen()),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.apartment,
                              label: 'Bulk CMO',
                              color: Colors.deepPurple,
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const BulkCMOStartScreen()),
                                );
                                _loadData();
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Recent CMOs
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent CMO Requests',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          if (_cmoList.isNotEmpty)
                            TextButton(
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const CMOScreen()),
                                );
                                _loadData();
                              },
                              child: const Text('View All'),
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Recent CMOs List
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_cmoList.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: 80,
                                  color: AppTheme.textHint,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No CMO requests yet',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textHint,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap "New CMO" to create your first request',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _cmoList.length > 5 ? 5 : _cmoList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final cmo = _cmoList[index];
                            return _buildCMOCard(cmo);
                          },
                        ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddCMOScreen()),
          );
          _loadData();
        },
        icon: const Icon(Icons.add),
        label: const Text('New CMO'),
      ),
    );
  }

  Widget _buildCMOCard(CMO cmo) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    Color statusColor;
    IconData statusIcon;
    switch (cmo.status.toLowerCase()) {
      case 'uploaded':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.cloud_done;
        break;
      case 'pending':
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.pending;
        break;
      case 'draft':
      default:
        statusColor = AppTheme.textSecondary;
        statusIcon = Icons.drafts;
    }

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to CMO screen for details
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CMOScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cmo.customerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cmo.mobileNumber,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          cmo.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
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
                  Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    dateFormat.format(cmo.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (cmo.customerId != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.person_outline, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cmo.customerId!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
