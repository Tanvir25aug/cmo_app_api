import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/app_theme.dart';
import '../../services/database_service.dart';
import '../../models/cmo_model.dart';
import '../../models/bulk_cmo_group_model.dart';
import 'bulk_cmo_meter_list_screen.dart';

class BulkCMOStartScreen extends StatefulWidget {
  const BulkCMOStartScreen({super.key});

  @override
  State<BulkCMOStartScreen> createState() => _BulkCMOStartScreenState();
}

class _BulkCMOStartScreenState extends State<BulkCMOStartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _houseNumberController = TextEditingController();
  final _meterCountController = TextEditingController();

  double? _latitude;
  double? _longitude;
  bool _isGettingLocation = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _houseNumberController.dispose();
    _meterCountController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled. Please enable them.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permissions are denied'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location captured successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  Future<void> _createBulkCMO() async {
    if (!_formKey.currentState!.validate()) return;

    final meterCount = int.tryParse(_meterCountController.text) ?? 0;
    if (meterCount < 1 || meterCount > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meter count must be between 1 and 50'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final houseNumber = _houseNumberController.text.trim();

      // Create BulkCMOGroup first
      final group = BulkCMOGroup(
        buildingName: houseNumber,
        latitude: _latitude,
        longitude: _longitude,
        meterCount: meterCount,
        completedCount: 0,
        status: 'draft',
      );

      final groupId = await DatabaseService.instance.createBulkCMOGroup(group);

      if (groupId == null) {
        throw Exception('Failed to create bulk CMO group');
      }

      // Create draft CMOs for each meter
      for (int i = 1; i <= meterCount; i++) {
        final cmo = CMO(
          customerName: '', // Will be filled when editing
          mobileNumber: '', // Will be filled when editing
          newMeterLatitude: _latitude,
          newMeterLongitude: _longitude,
          bulkGroupId: groupId,
          meterIndex: i,
          flatNo: 'Meter $i', // Default flat/meter label
          status: 'draft',
        );

        await DatabaseService.instance.createCMO(cmo);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created $meterCount CMO drafts for "$houseNumber"'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Navigate to meter list screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => BulkCMOMeterListScreen(
              bulkGroupId: groupId,
              buildingName: houseNumber,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Bulk CMO'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
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
                      Icons.apartment,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Multiple CMOs',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'For a building with multiple meters',
                          style: TextStyle(
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

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // House Number
                      _buildSectionTitle('House / Building Number'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _houseNumberController,
                        decoration: InputDecoration(
                          labelText: 'House Number *',
                          hintText: 'e.g., House #45, Building A',
                          prefixIcon: const Icon(Icons.home, color: Colors.deepPurple),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'House number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This will be used as the group label for all meters',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // GPS Location
                      _buildSectionTitle('GPS Location'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _latitude != null
                              ? AppTheme.successColor.withValues(alpha: 0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _latitude != null
                                ? AppTheme.successColor
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _latitude != null ? Icons.location_on : Icons.location_off,
                              color: _latitude != null
                                  ? AppTheme.successColor
                                  : AppTheme.textSecondary,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _latitude != null ? 'Location Captured' : 'No Location',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _latitude != null
                                          ? AppTheme.successColor
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                  if (_latitude != null && _longitude != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Lat: ${_latitude!.toStringAsFixed(6)}\nLng: ${_longitude!.toStringAsFixed(6)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _isGettingLocation ? null : _getCurrentLocation,
                              icon: _isGettingLocation
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.my_location, size: 18),
                              label: Text(_latitude != null ? 'Update' : 'Capture'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This location will be shared by all meters in this building',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Number of Meters
                      _buildSectionTitle('Number of Meters'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.deepPurple.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.electric_meter, color: Colors.deepPurple, size: 32),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'How many meters?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _meterCountController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: 'Enter number (1-50)',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      final count = int.tryParse(value);
                                      if (count == null || count < 1 || count > 50) {
                                        return 'Enter 1-50';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Info Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'What happens next?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Draft CMOs will be created for each meter. You can then fill in customer details for each meter using the normal CMO process.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
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

            // Bottom Button
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createBulkCMO,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline),
                            SizedBox(width: 8),
                            Text(
                              'CREATE DRAFT CMOs',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
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
            color: Colors.deepPurple,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
