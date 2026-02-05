import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../services/database_service.dart';
import '../../services/cmo_sync_service.dart';
import '../../models/cmo_model.dart';
import 'add_cmo_screen.dart';
import 'cmo_detail_screen.dart';
import 'bulk_cmo_start_screen.dart';
import 'bulk_cmo_groups_screen.dart';
import 'package:intl/intl.dart';

class CMOScreen extends StatefulWidget {
  const CMOScreen({super.key});

  @override
  State<CMOScreen> createState() => _CMOScreenState();
}

class _CMOScreenState extends State<CMOScreen> {
  List<CMO> _cmoList = [];
  List<CMO> _filteredCmoList = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  int _unsyncedCount = 0;

  // Filter and search state
  String _selectedFilter = 'all'; // all, draft, uploaded, synced
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCMOs();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _filteredCmoList = _cmoList.where((cmo) {
        // Apply status filter
        bool statusMatch = true;
        if (_selectedFilter == 'draft') {
          statusMatch = cmo.status.toLowerCase() == 'draft' && !cmo.isSynced;
        } else if (_selectedFilter == 'uploaded') {
          statusMatch = cmo.status.toLowerCase() == 'uploaded' && !cmo.isSynced;
        } else if (_selectedFilter == 'synced') {
          statusMatch = cmo.isSynced;
        }

        // Apply search filter
        bool searchMatch = true;
        final searchQuery = _searchController.text.trim().toLowerCase();
        if (searchQuery.isNotEmpty) {
          searchMatch = (cmo.customerId?.toLowerCase().contains(searchQuery) ?? false) ||
              (cmo.newMeterId?.toLowerCase().contains(searchQuery) ?? false) ||
              (cmo.oldMeterNumber?.toLowerCase().contains(searchQuery) ?? false);
        }

        return statusMatch && searchMatch;
      }).toList();
    });
  }

  Future<void> _loadCMOs() async {
    setState(() => _isLoading = true);

    try {
      final cmos = await DatabaseService.instance.getAllCMOs();
      final unsyncedCount = await DatabaseService.instance.getUploadedUnsyncedCount();
      if (mounted) {
        setState(() {
          _cmoList = cmos;
          _filteredCmoList = cmos;
          _unsyncedCount = unsyncedCount;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading CMOs: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _syncAllCMOs() async {
    if (_unsyncedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No uploaded CMOs to sync'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    // Confirm sync
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync to Server'),
        content: Text(
          'You are about to sync $_unsyncedCount uploaded CMO(s) to the server.\n\n'
          'After syncing, these records cannot be edited or deleted.\n\n'
          'Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Sync Now'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSyncing = true);

    try {
      final result = await CmoSyncService.instance.syncAllUploadedCMOs();

      if (mounted) {
        setState(() => _isSyncing = false);

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          // Show detailed error dialog
          _showSyncErrorDialog(result);
        }

        // Reload to update sync status
        _loadCMOs();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _navigateToAddCMO() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddCMOScreen(),
      ),
    );
    // Reload CMOs after returning from add screen
    _loadCMOs();
  }

  Future<void> _editCMO(CMO cmo) async {
    // Check if CMO is synced - cannot edit
    if (cmo.isSynced) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot edit synced CMO records'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Convert CMO object to map for passing to screens
    final cmoData = {
      'id': cmo.id,
      'customerId': cmo.customerId,
      'newMeterId': cmo.newMeterId,
      'customerName': cmo.customerName,
      'flatNo': cmo.flatNo,
      'floor': cmo.floor,
      'mobileNumber': cmo.mobileNumber,
      'secondaryMobileNumber': cmo.secondaryMobileNumber,
      'email': cmo.email,
      'nid': cmo.nid,
      'nocs': cmo.nocs,
      'feeder': cmo.feeder,
      'billGroup': cmo.billGroup,
      'sanctionLoad': cmo.sanctionLoad,
      'bookNumber': cmo.bookNumber,
      'tariff': cmo.tariff,
      'oldMeterType': cmo.oldMeterType,
      'oldMeterCategory': cmo.oldMeterCategory,
      'oldMeterNumber': cmo.oldMeterNumber,
      'oldMeterImagePath': cmo.oldMeterImagePath,
      'oldMeterReading': cmo.oldMeterReading,
      'onPeak': cmo.onPeak,
      'offPeak': cmo.offPeak,
      'kvar': cmo.kvar,
      'newMeterImagePath': cmo.newMeterImagePath,
      'newMeterLatitude': cmo.newMeterLatitude,
      'newMeterLongitude': cmo.newMeterLongitude,
      'batteryCoverSeal': cmo.batteryCoverSeal,
      'batteryCoverSealImagePath': cmo.batteryCoverSealImagePath,
      'terminalSeal1': cmo.terminalSeal1,
      'terminalSeal2': cmo.terminalSeal2,
      'terminalCoverSealImagePath': cmo.terminalCoverSealImagePath,
      'hasSteelBox': cmo.hasSteelBox,
      'installBy': cmo.installBy,
      'isEditMode': true,
    };

    // Navigate to Add CMO screen for editing (start from first page)
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddCMOScreen(cmoData: cmoData),
      ),
    );

    // Reload CMOs after returning from edit
    _loadCMOs();
  }

  Future<void> _deleteCMO(CMO cmo) async {
    // Check if CMO is synced - cannot delete
    if (cmo.isSynced) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete synced CMO records'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete CMO'),
        content: const Text('Are you sure you want to delete this CMO request?'),
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

    if (confirm == true) {
      final success = await DatabaseService.instance.deleteCMO(cmo.id!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CMO deleted successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadCMOs();
      }
    }
  }

  void _viewCMO(CMO cmo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CMODetailScreen(cmo: cmo),
      ),
    );
  }

  void _showSyncErrorDialog(BatchSyncResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.syncedCount > 0 ? Icons.warning_amber : Icons.error_outline,
              color: result.syncedCount > 0 ? AppTheme.warningColor : AppTheme.errorColor,
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Sync Result')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSyncStatItem('Total', result.totalCount, Colors.grey),
                    _buildSyncStatItem('Success', result.syncedCount, AppTheme.successColor),
                    _buildSyncStatItem('Failed', result.failedCount, AppTheme.errorColor),
                  ],
                ),
              ),

              if (result.errors != null && result.errors!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Errors:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ...result.errors!.take(5).map((error) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: AppTheme.errorColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          error,
                          style: const TextStyle(fontSize: 13, color: AppTheme.errorColor),
                        ),
                      ),
                    ],
                  ),
                )),
                if (result.errors!.length > 5)
                  Text(
                    '... and ${result.errors!.length - 5} more errors',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCMOCard(CMO cmo) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    Color statusColor;
    IconData statusIcon;
    String statusText;

    // Check if synced first
    if (cmo.isSynced) {
      statusColor = Colors.blue;
      statusIcon = Icons.cloud_done;
      statusText = 'SYNCED';
    } else {
      switch (cmo.status.toLowerCase()) {
        case 'uploaded':
          statusColor = AppTheme.successColor;
          statusIcon = Icons.cloud_upload;
          statusText = 'UPLOADED';
          break;
        case 'pending':
          statusColor = AppTheme.warningColor;
          statusIcon = Icons.pending;
          statusText = 'PENDING';
          break;
        case 'draft':
        default:
          statusColor = AppTheme.textSecondary;
          statusIcon = Icons.drafts;
          statusText = 'DRAFT';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _viewCMO(cmo),
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cmo.mobileNumber,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
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
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      Icons.person_outline,
                      'Customer ID',
                      cmo.customerId ?? 'N/A',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoRow(
                      Icons.electric_meter,
                      'New Meter',
                      cmo.newMeterId ?? 'N/A',
                    ),
                  ),
                ],
              ),
              if (cmo.oldMeterNumber != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.electric_meter_outlined,
                  'Old Meter',
                  cmo.oldMeterNumber!,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${dateFormat.format(cmo.createdAt)} at ${timeFormat.format(cmo.createdAt)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (cmo.isSynced && cmo.syncedAt != null)
                          Text(
                            'Synced: ${dateFormat.format(cmo.syncedAt!)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.blue,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // View button for all CMOs
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 22),
                    color: AppTheme.secondaryColor,
                    onPressed: () => _viewCMO(cmo),
                    tooltip: 'View',
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.all(4),
                  ),
                  // Only show edit/delete buttons if NOT synced
                  if (!cmo.isSynced) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 22),
                      color: AppTheme.primaryColor,
                      onPressed: () => _editCMO(cmo),
                      tooltip: 'Edit',
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: const EdgeInsets.all(4),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 22),
                      color: AppTheme.errorColor,
                      onPressed: () => _deleteCMO(cmo),
                      tooltip: 'Delete',
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: const EdgeInsets.all(4),
                    ),
                  ] else ...[
                    // Show lock icon for synced records
                    Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Colors.blue,
                        size: 22,
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

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    Color chipColor;

    switch (value) {
      case 'draft':
        chipColor = AppTheme.textSecondary;
        break;
      case 'uploaded':
        chipColor = AppTheme.successColor;
        break;
      case 'synced':
        chipColor = Colors.blue;
        break;
      default:
        chipColor = AppTheme.primaryColor;
    }

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : chipColor,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        _applyFilters();
      },
      selectedColor: chipColor,
      backgroundColor: chipColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : chipColor,
        fontWeight: FontWeight.w600,
      ),
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Collapsible Header
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryColor,
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
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.swap_horiz,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Change Meter Owner',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Manage meter ownership transfers',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              title: const Text('CMO'),
            ),

            // Sticky Controls Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action Buttons Row
                    Row(
                      children: [
                        // Add New CMO Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _navigateToAddCMO,
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            label: const Text('New CMO'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Bulk CMO Groups Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const BulkCMOGroupsScreen(),
                                ),
                              ).then((_) => _loadCMOs());
                            },
                            icon: const Icon(Icons.domain, size: 20),
                            label: const Text('Bulk Groups'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Sync Button - only show if there are unsynced uploaded CMOs
                    if (_unsyncedCount > 0)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ElevatedButton.icon(
                          onPressed: _isSyncing ? null : _syncAllCMOs,
                          icon: _isSyncing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.sync),
                          label: Text(
                            _isSyncing
                                ? 'Syncing...'
                                : 'Sync to Server ($_unsyncedCount pending)',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                    // Search Field
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by Customer ID, New Meter, Old Meter...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', 'all', Icons.list),
                          const SizedBox(width: 8),
                          _buildFilterChip('Draft', 'draft', Icons.drafts),
                          const SizedBox(width: 8),
                          _buildFilterChip('Uploaded', 'uploaded', Icons.cloud_upload),
                          const SizedBox(width: 8),
                          _buildFilterChip('Synced', 'synced', Icons.cloud_done),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // CMO List Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CMO Requests',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          '${_filteredCmoList.length} of ${_cmoList.length}',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // CMO List
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _filteredCmoList.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 80,
                                color: AppTheme.textHint,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _cmoList.isEmpty
                                    ? 'No CMO requests yet'
                                    : 'No CMOs match your filter',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.textHint,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _cmoList.isEmpty
                                    ? 'Tap "Add New CMO" to create your first request'
                                    : 'Try adjusting your search or filter',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final cmo = _filteredCmoList[index];
                              return _buildCMOCard(cmo);
                            },
                            childCount: _filteredCmoList.length,
                          ),
                        ),
                      ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Add CMO'),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'CMO Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.electric_meter, color: AppTheme.primaryColor),
              ),
              title: const Text('Single CMO'),
              subtitle: const Text('Add one meter at a time'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _navigateToAddCMO();
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_business, color: Colors.deepPurple),
              ),
              title: const Text('New Bulk CMO'),
              subtitle: const Text('Create CMOs for a building'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BulkCMOStartScreen(),
                  ),
                ).then((_) => _loadCMOs());
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.domain, color: Colors.orange),
              ),
              title: const Text('View Bulk CMO Groups'),
              subtitle: const Text('Manage existing building groups'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BulkCMOGroupsScreen(),
                  ),
                ).then((_) => _loadCMOs());
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
