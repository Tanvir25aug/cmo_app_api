import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../services/database_service.dart';
import '../../models/bulk_cmo_group_model.dart';
import 'bulk_cmo_meter_list_screen.dart';
import 'bulk_cmo_start_screen.dart';

class BulkCMOGroupsScreen extends StatefulWidget {
  const BulkCMOGroupsScreen({super.key});

  @override
  State<BulkCMOGroupsScreen> createState() => _BulkCMOGroupsScreenState();
}

class _BulkCMOGroupsScreenState extends State<BulkCMOGroupsScreen> {
  bool _isLoading = true;
  List<BulkCMOGroup> _groups = [];
  Map<String, Map<String, int>> _groupStatusCounts = {};

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);

    try {
      final groups = await DatabaseService.instance.getAllBulkCMOGroups();

      // Get status counts for each group
      final statusCounts = <String, Map<String, int>>{};
      for (final group in groups) {
        if (group.id != null) {
          statusCounts[group.id!] = await DatabaseService.instance
              .getCMOStatusCountsByBulkGroup(group.id!);
        }
      }

      if (mounted) {
        setState(() {
          _groups = groups;
          _groupStatusCounts = statusCounts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading groups: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _navigateToGroup(BulkCMOGroup group) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BulkCMOMeterListScreen(
          bulkGroupId: group.id!,
          buildingName: group.buildingName ?? 'Unknown Building',
        ),
      ),
    ).then((_) => _loadGroups());
  }

  void _navigateToNewBulkCMO() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const BulkCMOStartScreen(),
      ),
    ).then((_) => _loadGroups());
  }

  Future<void> _deleteGroup(BulkCMOGroup group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          'Are you sure you want to delete "${group.buildingName}"?\n\n'
          'This will also delete all ${group.meterCount} CMO(s) in this group.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && group.id != null) {
      final success = await DatabaseService.instance.deleteBulkCMOGroup(group.id!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group deleted successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadGroups();
      }
    }
  }

  Widget _buildGroupCard(BulkCMOGroup group) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final counts = _groupStatusCounts[group.id] ?? {'draft': 0, 'uploaded': 0, 'synced': 0, 'total': 0};

    final draftCount = counts['draft'] ?? 0;
    final uploadedCount = counts['uploaded'] ?? 0;
    final syncedCount = counts['synced'] ?? 0;
    final totalCount = counts['total'] ?? group.meterCount;

    // Calculate progress
    final completedCount = uploadedCount + syncedCount;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    // Determine overall status color
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (syncedCount == totalCount && totalCount > 0) {
      statusColor = Colors.blue;
      statusText = 'SYNCED';
      statusIcon = Icons.cloud_done;
    } else if (uploadedCount > 0 || syncedCount > 0) {
      statusColor = AppTheme.successColor;
      statusText = 'IN PROGRESS';
      statusIcon = Icons.trending_up;
    } else {
      statusColor = AppTheme.textSecondary;
      statusText = 'DRAFT';
      statusIcon = Icons.drafts;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToGroup(group),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.apartment,
                      color: Colors.deepPurple,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.buildingName ?? 'Unknown Building',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Group: ${group.id?.substring(0, 8) ?? 'N/A'}...',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Meter Count Row
              Row(
                children: [
                  const Icon(Icons.electric_meter, size: 18, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Text(
                    '$totalCount Meter${totalCount != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateFormat.format(group.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Status Breakdown
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildStatusChip('Draft', draftCount, AppTheme.textSecondary, Icons.drafts),
                    const SizedBox(width: 8),
                    _buildStatusChip('Uploaded', uploadedCount, AppTheme.successColor, Icons.cloud_upload),
                    const SizedBox(width: 8),
                    _buildStatusChip('Synced', syncedCount, Colors.blue, Icons.cloud_done),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Completion',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: progress == 1.0 ? AppTheme.successColor : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 1.0 ? AppTheme.successColor : Colors.deepPurple,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _navigateToGroup(group),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('View'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                    ),
                  ),
                  if (syncedCount < totalCount) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _deleteGroup(group),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
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

  Widget _buildStatusChip(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk CMO Groups'),
        elevation: 0,
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepPurple,
                  Colors.deepPurple.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.domain,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Building Groups',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_groups.length} group${_groups.length != 1 ? 's' : ''} total',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _groups.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.apartment_outlined,
                              size: 80,
                              color: AppTheme.textHint,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No bulk CMO groups yet',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textHint,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create a new bulk CMO for a building',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _navigateToNewBulkCMO,
                              icon: const Icon(Icons.add),
                              label: const Text('New Bulk CMO'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadGroups,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _groups.length,
                          itemBuilder: (context, index) {
                            return _buildGroupCard(_groups[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: _groups.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _navigateToNewBulkCMO,
              backgroundColor: Colors.deepPurple,
              icon: const Icon(Icons.add),
              label: const Text('New Group'),
            )
          : null,
    );
  }
}
