import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../models/cmo_model.dart';

class CMODetailScreen extends StatelessWidget {
  final CMO cmo;

  const CMODetailScreen({super.key, required this.cmo});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('CMO Details'),
        elevation: 0,
        actions: [
          // Show sync status badge
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Chip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cmo.isSynced ? Icons.cloud_done : Icons.cloud_upload,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    cmo.isSynced ? 'SYNCED' : cmo.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              backgroundColor: cmo.isSynced
                  ? Colors.blue
                  : (cmo.status == 'uploaded'
                      ? AppTheme.successColor
                      : AppTheme.textSecondary),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Information Section
            _buildSectionTitle('Customer Information'),
            const SizedBox(height: 16),
            _buildInfoCard([
              _buildInfoItem('Customer ID', cmo.customerId ?? 'N/A'),
              _buildInfoItem('Customer Name', cmo.customerName),
              _buildInfoItem('Mobile Number', cmo.mobileNumber),
              if (cmo.secondaryMobileNumber != null && cmo.secondaryMobileNumber!.isNotEmpty)
                _buildInfoItem('Secondary Mobile', cmo.secondaryMobileNumber!),
              if (cmo.email != null && cmo.email!.isNotEmpty)
                _buildInfoItem('Email', cmo.email!),
              if (cmo.nid != null && cmo.nid!.isNotEmpty)
                _buildInfoItem('NID', cmo.nid!),
            ]),

            const SizedBox(height: 24),

            // Address Information Section
            _buildSectionTitle('Address Information'),
            const SizedBox(height: 16),
            _buildInfoCard([
              if (cmo.flatNo != null && cmo.flatNo!.isNotEmpty)
                _buildInfoItem('Flat No', cmo.flatNo!),
              if (cmo.floor != null && cmo.floor!.isNotEmpty)
                _buildInfoItem('Floor', cmo.floor!),
              if (cmo.nocs != null && cmo.nocs!.isNotEmpty)
                _buildInfoItem('NOCS', cmo.nocs!),
              if (cmo.feeder != null && cmo.feeder!.isNotEmpty)
                _buildInfoItem('Feeder', cmo.feeder!),
              if (cmo.billGroup != null && cmo.billGroup!.isNotEmpty)
                _buildInfoItem('Bill Group', cmo.billGroup!),
            ]),

            const SizedBox(height: 24),

            // Meter Information Section
            _buildSectionTitle('Meter Information'),
            const SizedBox(height: 16),
            _buildInfoCard([
              if (cmo.sanctionLoad != null && cmo.sanctionLoad!.isNotEmpty)
                _buildInfoItem('Sanction Load', cmo.sanctionLoad!),
              if (cmo.bookNumber != null && cmo.bookNumber!.isNotEmpty)
                _buildInfoItem('Book Number', cmo.bookNumber!),
              if (cmo.tariff != null && cmo.tariff!.isNotEmpty)
                _buildInfoItem('Tariff', cmo.tariff!),
            ]),

            const SizedBox(height: 24),

            // Old Meter Section
            _buildSectionTitle('Old Meter Details'),
            const SizedBox(height: 16),
            _buildInfoCard([
              if (cmo.oldMeterType != null && cmo.oldMeterType!.isNotEmpty)
                _buildInfoItem('Meter Type', cmo.oldMeterType == '1P' ? '1P (Single Phase)' : '3P (Three Phase)'),
              if (cmo.oldMeterCategory != null && cmo.oldMeterCategory!.isNotEmpty)
                _buildInfoItem('Meter Category', cmo.oldMeterCategory == 'postpaid' ? 'Postpaid' : 'Prepaid'),
              if (cmo.oldMeterNumber != null && cmo.oldMeterNumber!.isNotEmpty)
                _buildInfoItem('Old Meter Number', cmo.oldMeterNumber!),
              if (cmo.oldMeterReading != null && cmo.oldMeterReading!.isNotEmpty)
                _buildInfoItem(
                  cmo.oldMeterCategory == 'prepaid' ? 'Balance (Taka)' : 'Meter Reading',
                  cmo.oldMeterReading!,
                ),
              if (cmo.oldMeterCategory != 'prepaid') ...[
                if (cmo.onPeak != null && cmo.onPeak!.isNotEmpty)
                  _buildInfoItem('On-Peak', cmo.onPeak!),
                if (cmo.offPeak != null && cmo.offPeak!.isNotEmpty)
                  _buildInfoItem('Off-Peak', cmo.offPeak!),
                if (cmo.kvar != null && cmo.kvar!.isNotEmpty)
                  _buildInfoItem('KVAR', cmo.kvar!),
              ],
            ]),

            // Old Meter Image
            if (cmo.oldMeterImagePath != null && cmo.oldMeterImagePath!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildImageSection('Old Meter Photo', cmo.oldMeterImagePath!),
            ],

            const SizedBox(height: 24),

            // New Meter Section
            _buildSectionTitle('New Meter Details'),
            const SizedBox(height: 16),
            _buildInfoCard([
              _buildInfoItem('New Meter ID', cmo.newMeterId ?? 'N/A'),
              if (cmo.newMeterLatitude != null && cmo.newMeterLongitude != null)
                _buildInfoItem(
                  'GPS Location',
                  'Lat: ${cmo.newMeterLatitude!.toStringAsFixed(6)}, Lng: ${cmo.newMeterLongitude!.toStringAsFixed(6)}',
                ),
            ]),

            // New Meter Image
            if (cmo.newMeterImagePath != null && cmo.newMeterImagePath!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildImageSection('New Meter Photo', cmo.newMeterImagePath!),
            ],

            const SizedBox(height: 24),

            // Seal Information Section
            _buildSectionTitle('Seal Information'),
            const SizedBox(height: 16),
            _buildInfoCard([
              if (cmo.batteryCoverSeal != null && cmo.batteryCoverSeal!.isNotEmpty)
                _buildInfoItem('Battery Cover Seal', cmo.batteryCoverSeal!),
              if (cmo.terminalSeal1 != null && cmo.terminalSeal1!.isNotEmpty)
                _buildInfoItem('Terminal Seal 1', cmo.terminalSeal1!),
              if (cmo.terminalSeal2 != null && cmo.terminalSeal2!.isNotEmpty)
                _buildInfoItem('Terminal Seal 2', cmo.terminalSeal2!),
              _buildInfoItem('Steel Box', cmo.hasSteelBox ? 'Yes' : 'No'),
            ]),

            // Battery Cover Seal Image
            if (cmo.batteryCoverSealImagePath != null && cmo.batteryCoverSealImagePath!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildImageSection('Battery Cover Seal Photo', cmo.batteryCoverSealImagePath!),
            ],

            // Terminal Cover Seal Image
            if (cmo.terminalCoverSealImagePath != null && cmo.terminalCoverSealImagePath!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildImageSection('Terminal Cover Seal Photo', cmo.terminalCoverSealImagePath!),
            ],

            const SizedBox(height: 24),

            // Installation Information Section
            _buildSectionTitle('Installation Information'),
            const SizedBox(height: 16),
            _buildInfoCard([
              if (cmo.installBy != null && cmo.installBy!.isNotEmpty)
                _buildInfoItem('Installed By', cmo.installBy!),
              if (cmo.installDate != null)
                _buildInfoItem('Install Date', dateFormat.format(cmo.installDate!)),
              _buildInfoItem('Created At', '${dateFormat.format(cmo.createdAt)} at ${timeFormat.format(cmo.createdAt)}'),
              if (cmo.updatedAt != null)
                _buildInfoItem('Updated At', '${dateFormat.format(cmo.updatedAt!)} at ${timeFormat.format(cmo.updatedAt!)}'),
              if (cmo.isSynced && cmo.syncedAt != null)
                _buildInfoItem('Synced At', '${dateFormat.format(cmo.syncedAt!)} at ${timeFormat.format(cmo.syncedAt!)}'),
            ]),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    // Filter out null widgets
    final filteredChildren = children.where((w) => w is! SizedBox || (w as SizedBox).height != 0).toList();

    if (filteredChildren.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text(
          'No information available',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: filteredChildren,
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(String title, String imagePath) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<bool>(
          future: File(imagePath).exists(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.data == true) {
              return GestureDetector(
                onTap: () {
                  // Show full screen image
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _FullScreenImage(imagePath: imagePath, title: title),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryColor, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImagePlaceholder('Image could not be loaded');
                          },
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.fullscreen,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return _buildImagePlaceholder('Image not found');
            }
          },
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder(String message) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningColor, width: 2),
        color: AppTheme.warningColor.withOpacity(0.1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 40,
            color: AppTheme.warningColor,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: AppTheme.warningColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final String imagePath;
  final String title;

  const _FullScreenImage({required this.imagePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(title),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
