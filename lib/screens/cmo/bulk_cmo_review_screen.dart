import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../services/database_service.dart';
import '../../services/cmo_sync_service.dart';
import '../../models/bulk_cmo_group_model.dart';
import '../../models/cmo_model.dart';

class BulkCMOReviewScreen extends StatefulWidget {
  final String bulkGroupId;
  final String buildingName;

  const BulkCMOReviewScreen({
    super.key,
    required this.bulkGroupId,
    required this.buildingName,
  });

  @override
  State<BulkCMOReviewScreen> createState() => _BulkCMOReviewScreenState();
}

class _BulkCMOReviewScreenState extends State<BulkCMOReviewScreen> {
  bool _isLoading = true;
  bool _isSyncing = false;
  BulkCMOGroup? _group;
  List<BulkMeterEntry> _entries = [];
  List<CMO> _cmos = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final group = await DatabaseService.instance.getBulkCMOGroupById(widget.bulkGroupId);
      final entries = await DatabaseService.instance.getBulkMeterEntries(widget.bulkGroupId);
      final cmos = await DatabaseService.instance.getCMOsByBulkGroupId(widget.bulkGroupId);

      if (mounted) {
        setState(() {
          _group = group;
          _entries = entries;
          _cmos = cmos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  CMO? _getCMOForEntry(BulkMeterEntry entry) {
    if (entry.cmoId == null) return null;
    try {
      return _cmos.firstWhere((cmo) => cmo.id == entry.cmoId);
    } catch (e) {
      return null;
    }
  }

  List<BulkMeterEntry> get _completedEntries =>
      _entries.where((e) => e.isComplete).toList();

  List<BulkMeterEntry> get _incompleteEntries =>
      _entries.where((e) => !e.isComplete).toList();

  Future<void> _handleUpload() async {
    final completedCount = _completedEntries.length;

    if (completedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No completed meters to upload'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    // Confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Upload'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to upload $completedCount CMO(s) for:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.apartment, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.buildingName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            if (_incompleteEntries.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warningColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: AppTheme.warningColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_incompleteEntries.length} meter(s) are incomplete and will not be uploaded.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
            child: const Text('Upload'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSyncing = true);

    try {
      // Update all completed CMOs status to 'uploaded'
      for (final entry in _completedEntries) {
        final cmo = _getCMOForEntry(entry);
        if (cmo != null) {
          final updatedCmo = cmo.copyWith(status: 'uploaded');
          await DatabaseService.instance.updateCMO(updatedCmo);
        }
      }

      // Update bulk group status
      if (_group != null) {
        final updatedGroup = _group!.copyWith(status: 'uploaded');
        await DatabaseService.instance.updateBulkCMOGroup(updatedGroup);
      }

      // Now sync with server
      await _syncWithServer();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _syncWithServer() async {
    try {
      // Get all CMOs for this bulk group that are uploaded but not synced
      final cmosToSync = _cmos.where((cmo) =>
          cmo.status == 'uploaded' && !cmo.isSynced &&
          cmo.newMeterId != null && cmo.newMeterId!.isNotEmpty
      ).toList();

      if (cmosToSync.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All CMOs are already synced!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        return;
      }

      // Sync each CMO
      int successCount = 0;
      int failCount = 0;

      for (final cmo in cmosToSync) {
        final result = await CmoSyncService.instance.syncCMO(cmo);
        if (result.success) {
          successCount++;
        } else {
          failCount++;
        }
      }

      // Mark bulk group as synced if all successful
      if (failCount == 0 && _group != null) {
        await DatabaseService.instance.markBulkGroupAsSynced(_group!.id!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failCount == 0
                  ? 'All $successCount CMOs synced successfully!'
                  : '$successCount synced, $failCount failed',
            ),
            backgroundColor: failCount == 0 ? AppTheme.successColor : AppTheme.warningColor,
          ),
        );

        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _handleSaveDraft() async {
    try {
      if (_group != null) {
        final status = _completedEntries.isEmpty
            ? 'draft'
            : _completedEntries.length < _entries.length
                ? 'partial'
                : 'complete';

        final updatedGroup = _group!.copyWith(status: status);
        await DatabaseService.instance.updateBulkCMOGroup(updatedGroup);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved as draft successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving draft: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _completedEntries.length;
    final totalCount = _entries.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Upload'),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Summary Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.successColor,
                          AppTheme.successColor.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.apartment,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.buildingName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$completedCount of $totalCount meters complete',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_group?.latitude != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.white70, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                '${_group!.latitude!.toStringAsFixed(4)}, ${_group!.longitude!.toStringAsFixed(4)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Stats Row
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _StatChip(
                          icon: Icons.check_circle,
                          label: 'Complete',
                          value: _completedEntries.length,
                          color: AppTheme.successColor,
                        ),
                        const SizedBox(width: 12),
                        _StatChip(
                          icon: Icons.pending,
                          label: 'Incomplete',
                          value: _incompleteEntries.length,
                          color: AppTheme.warningColor,
                        ),
                        const SizedBox(width: 12),
                        _StatChip(
                          icon: Icons.electric_meter,
                          label: 'Total',
                          value: totalCount,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),

                  // CMO List
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        if (_completedEntries.isNotEmpty) ...[
                          _buildSectionHeader('Ready to Upload', _completedEntries.length, AppTheme.successColor),
                          ..._completedEntries.map((entry) => _CMOReviewCard(
                                entry: entry,
                                cmo: _getCMOForEntry(entry),
                                isComplete: true,
                              )),
                        ],
                        if (_incompleteEntries.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildSectionHeader('Incomplete', _incompleteEntries.length, AppTheme.warningColor),
                          ..._incompleteEntries.map((entry) => _CMOReviewCard(
                                entry: entry,
                                cmo: _getCMOForEntry(entry),
                                isComplete: false,
                              )),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Bottom Actions
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: _isSyncing
                        ? const Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text('Syncing with server...'),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _handleSaveDraft,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: const BorderSide(color: AppTheme.warningColor, width: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'SAVE DRAFT',
                                    style: TextStyle(
                                      color: AppTheme.warningColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: _completedEntries.isNotEmpty ? _handleUpload : null,
                                  icon: const Icon(Icons.cloud_upload),
                                  label: Text('UPLOAD (${_completedEntries.length})'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.successColor,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CMOReviewCard extends StatelessWidget {
  final BulkMeterEntry entry;
  final CMO? cmo;
  final bool isComplete;

  const _CMOReviewCard({
    required this.entry,
    this.cmo,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isComplete ? AppTheme.successColor.withValues(alpha: 0.3) : Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isComplete
                    ? AppTheme.successColor.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: isComplete
                    ? const Icon(Icons.check, color: AppTheme.successColor, size: 20)
                    : Text(
                        '${entry.meterIndex}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (entry.newMeterId != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Meter: ${entry.newMeterId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                  if (cmo?.customerName != null && cmo!.customerName.isNotEmpty) ...[
                    Text(
                      'Customer: ${cmo!.customerName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isComplete)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Incomplete',
                  style: TextStyle(
                    color: AppTheme.warningColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
