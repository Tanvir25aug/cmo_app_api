import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../services/database_service.dart';
import '../../models/bulk_cmo_group_model.dart';
import '../../models/cmo_model.dart';
import 'barcode_scanner_screen.dart';
import 'add_cmo_screen.dart';

class BulkCMOMeterListScreen extends StatefulWidget {
  final String bulkGroupId;
  final String buildingName;

  const BulkCMOMeterListScreen({
    super.key,
    required this.bulkGroupId,
    required this.buildingName,
  });

  @override
  State<BulkCMOMeterListScreen> createState() => _BulkCMOMeterListScreenState();
}

class _BulkCMOMeterListScreenState extends State<BulkCMOMeterListScreen> {
  bool _isLoading = true;
  BulkCMOGroup? _group;
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
      final cmos = await DatabaseService.instance.getCMOsByBulkGroupId(widget.bulkGroupId);

      if (mounted) {
        setState(() {
          _group = group;
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

  Future<void> _scanMeterQR(CMO cmo) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerScreen(),
      ),
    );

    if (result != null && result is String && mounted) {
      // Check for duplicate meter ID
      final isDuplicate = await DatabaseService.instance.isNewMeterIdDuplicate(
        result,
        excludeCmoId: cmo.id,
      );

      if (isDuplicate) {
        final existingCmo = await DatabaseService.instance.getCMOByNewMeterId(result);
        if (mounted) {
          _showDuplicateError(
            'Duplicate Meter Number',
            'Meter $result already exists!\n'
            'Customer: ${existingCmo?.customerName ?? "N/A"}\n'
            'Status: ${existingCmo?.status ?? "N/A"}\n\n'
            'Cannot save duplicate meter number.',
          );
        }
        return;
      }

      // Update CMO with new meter ID
      final updatedCmo = CMO(
        id: cmo.id,
        customerId: cmo.customerId,
        newMeterId: result,
        customerName: cmo.customerName,
        flatNo: cmo.flatNo,
        floor: cmo.floor,
        mobileNumber: cmo.mobileNumber,
        secondaryMobileNumber: cmo.secondaryMobileNumber,
        email: cmo.email,
        nid: cmo.nid,
        nocs: cmo.nocs,
        feeder: cmo.feeder,
        billGroup: cmo.billGroup,
        sanctionLoad: cmo.sanctionLoad,
        bookNumber: cmo.bookNumber,
        tariff: cmo.tariff,
        oldMeterType: cmo.oldMeterType,
        oldMeterCategory: cmo.oldMeterCategory,
        oldMeterNumber: cmo.oldMeterNumber,
        oldMeterImagePath: cmo.oldMeterImagePath,
        oldMeterReading: cmo.oldMeterReading,
        onPeak: cmo.onPeak,
        offPeak: cmo.offPeak,
        kvar: cmo.kvar,
        newMeterImagePath: cmo.newMeterImagePath,
        newMeterLatitude: cmo.newMeterLatitude,
        newMeterLongitude: cmo.newMeterLongitude,
        installDate: cmo.installDate,
        batteryCoverSeal: cmo.batteryCoverSeal,
        batteryCoverSealImagePath: cmo.batteryCoverSealImagePath,
        terminalSeal1: cmo.terminalSeal1,
        terminalSeal2: cmo.terminalSeal2,
        terminalCoverSealImagePath: cmo.terminalCoverSealImagePath,
        hasSteelBox: cmo.hasSteelBox,
        installBy: cmo.installBy,
        status: cmo.status,
        bulkGroupId: cmo.bulkGroupId,
        meterIndex: cmo.meterIndex,
      );

      await DatabaseService.instance.updateCMO(updatedCmo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meter $result assigned successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
      _loadData();
    }
  }

  void _showDuplicateError(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: AppTheme.errorColor, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _editCMO(CMO cmo) async {
    // Convert CMO to map for editing
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
      'feeder': cmo.feeder ?? _group?.feeder,
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
      'newMeterLatitude': cmo.newMeterLatitude ?? _group?.latitude,
      'newMeterLongitude': cmo.newMeterLongitude ?? _group?.longitude,
      'installDate': cmo.installDate,
      'batteryCoverSeal': cmo.batteryCoverSeal,
      'batteryCoverSealImagePath': cmo.batteryCoverSealImagePath,
      'terminalSeal1': cmo.terminalSeal1,
      'terminalSeal2': cmo.terminalSeal2,
      'terminalCoverSealImagePath': cmo.terminalCoverSealImagePath,
      'hasSteelBox': cmo.hasSteelBox,
      'installBy': cmo.installBy ?? _group?.installBy,
      'bulkGroupId': cmo.bulkGroupId,
      'meterIndex': cmo.meterIndex,
      'isEditMode': true,
    };

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddCMOScreen(cmoData: cmoData),
      ),
    );

    _loadData();
  }

  Color _getStatusColor(CMO cmo) {
    if (cmo.isSynced) return Colors.blue;
    switch (cmo.status.toLowerCase()) {
      case 'uploaded':
        return AppTheme.successColor;
      case 'draft':
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getStatusText(CMO cmo) {
    if (cmo.isSynced) return 'SYNCED';
    switch (cmo.status.toLowerCase()) {
      case 'uploaded':
        return 'UPLOADED';
      case 'draft':
      default:
        return 'DRAFT';
    }
  }

  IconData _getStatusIcon(CMO cmo) {
    if (cmo.isSynced) return Icons.cloud_done;
    switch (cmo.status.toLowerCase()) {
      case 'uploaded':
        return Icons.cloud_upload;
      case 'draft':
      default:
        return Icons.drafts;
    }
  }

  bool _isCMOComplete(CMO cmo) {
    return cmo.status.toLowerCase() == 'uploaded' || cmo.isSynced;
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _cmos.where((c) => _isCMOComplete(c)).length;
    final draftCount = _cmos.where((c) => c.status.toLowerCase() == 'draft' && !c.isSynced).length;
    final uploadedCount = _cmos.where((c) => c.status.toLowerCase() == 'uploaded' && !c.isSynced).length;
    final syncedCount = _cmos.where((c) => c.isSynced).length;
    final totalCount = _cmos.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.buildingName),
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Header
            Container(
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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Group: ${widget.bulkGroupId.length > 8 ? '${widget.bulkGroupId.substring(0, 8)}...' : widget.bulkGroupId}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalCount Meter${totalCount != 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Status breakdown
                  Row(
                    children: [
                      _buildStatusBadge('Draft', draftCount, AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      _buildStatusBadge('Uploaded', uploadedCount, AppTheme.successColor),
                      const SizedBox(width: 8),
                      _buildStatusBadge('Synced', syncedCount, Colors.blue),
                    ],
                  ),

                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),

            // Meter List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _cmos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.electric_meter_outlined,
                                size: 64,
                                color: AppTheme.textHint,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No meters in this group',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppTheme.textHint,
                                    ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _cmos.length,
                            itemBuilder: (context, index) {
                              final cmo = _cmos[index];
                              return _buildMeterCard(cmo);
                            },
                          ),
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
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.deepPurple, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'BACK',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
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

  Widget _buildStatusBadge(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeterCard(CMO cmo) {
    final statusColor = _getStatusColor(cmo);
    final statusText = _getStatusText(cmo);
    final statusIcon = _getStatusIcon(cmo);
    final isComplete = _isCMOComplete(cmo);
    final hasNewMeter = cmo.newMeterId != null && cmo.newMeterId!.isNotEmpty;
    final hasCustomer = cmo.customerName.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isComplete ? statusColor : Colors.grey.shade300,
          width: isComplete ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: cmo.isSynced ? null : () => _editCMO(cmo),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Index Badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: isComplete
                          ? Icon(Icons.check, color: statusColor, size: 24)
                          : Text(
                              '${cmo.meterIndex ?? "?"}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: statusColor,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasCustomer ? cmo.customerName : cmo.flatNo ?? 'Meter ${cmo.meterIndex}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (hasNewMeter)
                          Row(
                            children: [
                              Icon(Icons.electric_meter, size: 14, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  cmo.newMeterId!,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            'No meter ID assigned',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        if (cmo.customerId != null && cmo.customerId!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 14, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'ID: ${cmo.customerId}',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                          statusText,
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

              // Quick Actions (only for non-synced)
              if (!cmo.isSynced) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _scanMeterQR(cmo),
                        icon: const Icon(Icons.qr_code_scanner, size: 16),
                        label: Text(
                          hasNewMeter ? 'Rescan' : 'Scan',
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.deepPurple,
                          side: const BorderSide(color: Colors.deepPurple),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _editCMO(cmo),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text(
                          'Edit',
                          style: TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      'Synced - Cannot be edited',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
