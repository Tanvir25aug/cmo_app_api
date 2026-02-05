import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../services/database_service.dart';
import '../../services/ocr_service.dart';
import '../../services/auth_service.dart';
import '../../models/cmo_model.dart';
import 'barcode_scanner_screen.dart';

class SealInfoScreen extends StatefulWidget {
  final Map<String, dynamic> cmoData;

  const SealInfoScreen({super.key, required this.cmoData});

  @override
  State<SealInfoScreen> createState() => _SealInfoScreenState();
}

class _SealInfoScreenState extends State<SealInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _batteryCoverSealController = TextEditingController();
  final _terminalSeal1Controller = TextEditingController();
  final _terminalSeal2Controller = TextEditingController();
  final _installByController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _batteryCoverSealImagePath;
  String? _terminalCoverSealImagePath;
  bool _isCapturingBattery = false;
  bool _isCapturingTerminal = false;
  bool _hasSteelBox = false;
  bool _isLoading = false;
  DateTime _installDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Set current user as installer from AuthService
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setCurrentUserAsInstaller();
    });

    // Pre-fill data if in edit mode
    if (widget.cmoData['isEditMode'] == true) {
      _batteryCoverSealController.text = widget.cmoData['batteryCoverSeal'] ?? '';
      _terminalSeal1Controller.text = widget.cmoData['terminalSeal1'] ?? '';
      _terminalSeal2Controller.text = widget.cmoData['terminalSeal2'] ?? '';
      _batteryCoverSealImagePath = widget.cmoData['batteryCoverSealImagePath'];
      _terminalCoverSealImagePath = widget.cmoData['terminalCoverSealImagePath'];
      _hasSteelBox = widget.cmoData['hasSteelBox'] == '1' || widget.cmoData['hasSteelBox'] == 1 || widget.cmoData['hasSteelBox'] == true;
      if (widget.cmoData['installBy'] != null && widget.cmoData['installBy'].toString().isNotEmpty) {
        _installByController.text = widget.cmoData['installBy'];
      }
      // Pre-fill install date if available
      if (widget.cmoData['installDate'] != null) {
        if (widget.cmoData['installDate'] is DateTime) {
          _installDate = widget.cmoData['installDate'];
        } else if (widget.cmoData['installDate'] is String) {
          _installDate = DateTime.tryParse(widget.cmoData['installDate']) ?? DateTime.now();
        }
      }
    }
  }

  void _setCurrentUserAsInstaller() {
    if (!mounted) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    // Only set if installBy is empty (not in edit mode with existing value)
    if (_installByController.text.isEmpty || _installByController.text == 'Current User') {
      setState(() {
        _installByController.text = currentUser?.username ?? currentUser?.fullName ?? 'Unknown User';
      });
    }
  }

  @override
  void dispose() {
    _batteryCoverSealController.dispose();
    _terminalSeal1Controller.dispose();
    _terminalSeal2Controller.dispose();
    _installByController.dispose();
    super.dispose();
  }

  Future<void> _captureImage(ImageSource source, String sealType) async {
    try {
      if (sealType == 'battery') {
        setState(() => _isCapturingBattery = true);
      } else {
        setState(() => _isCapturingTerminal = true);
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null && mounted) {
        if (sealType == 'battery') {
          setState(() {
            _batteryCoverSealImagePath = image.path;
          });
          // Process OCR for battery cover seal
          await _processSealOcr(image.path, sealType);
        } else {
          setState(() {
            _terminalCoverSealImagePath = image.path;
          });
          // Process OCR for terminal cover seal
          await _processSealOcr(image.path, sealType);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing image: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        if (sealType == 'battery') {
          setState(() => _isCapturingBattery = false);
        } else {
          setState(() => _isCapturingTerminal = false);
        }
      }
    }
  }

  Future<void> _processSealOcr(String imagePath, String sealType) async {
    try {
      final result = await OcrService.instance.extractSealNumber(imagePath);

      if (!mounted) return;

      if (result.success && result.sealNumbers != null && result.sealNumbers!.isNotEmpty) {
        // Show seal selection dialog
        _showSealSelectionDialog(result.sealNumbers!, sealType);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Could not detect seal number. Please enter manually.'),
            backgroundColor: AppTheme.warningColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showSealSelectionDialog(List<String> sealNumbers, String sealType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.document_scanner, color: AppTheme.successColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sealType == 'battery' ? 'Battery Cover Seal OCR' : 'Terminal Cover Seal OCR',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to select the correct seal number:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: sealNumbers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final sealNumber = sealNumbers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        sealNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        if (sealType == 'battery') {
                          _batteryCoverSealController.text = sealNumber;
                        } else {
                          // For terminal, show dialog to choose which seal field
                          Navigator.pop(context);
                          _showTerminalSealFieldDialog(sealNumber);
                          return;
                        }
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Seal number "$sealNumber" selected'),
                            backgroundColor: AppTheme.successColor,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppTheme.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Enter Manually Instead'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTerminalSealFieldDialog(String sealNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Seal Field'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.looks_one),
              title: const Text('Terminal Seal 1'),
              onTap: () {
                _terminalSeal1Controller.text = sealNumber;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Seal 1: "$sealNumber" selected'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.looks_two),
              title: const Text('Terminal Seal 2'),
              onTap: () {
                _terminalSeal2Controller.text = sealNumber;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Seal 2: "$sealNumber" selected'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Scan QR code for seal numbers
  Future<void> _scanSealQRCode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      // Show dialog to select which seal field to fill
      _showSealFieldSelectionDialog(result);
    }
  }

  // Dialog to select which seal field to fill with the scanned QR value
  void _showSealFieldSelectionDialog(String scannedValue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.qr_code_scanner, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            const Expanded(child: Text('Select Seal Field')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      scannedValue,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select which seal field to fill:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.battery_full, color: Colors.white, size: 20),
              ),
              title: const Text('Battery Cover Seal'),
              subtitle: Text(
                _batteryCoverSealController.text.isEmpty
                    ? 'Empty'
                    : _batteryCoverSealController.text,
                style: TextStyle(
                  color: _batteryCoverSealController.text.isEmpty
                      ? Colors.grey
                      : AppTheme.successColor,
                ),
              ),
              onTap: () {
                _batteryCoverSealController.text = scannedValue;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Battery Cover Seal: "$scannedValue"'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orange,
                child: Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: const Text('Terminal Seal 1'),
              subtitle: Text(
                _terminalSeal1Controller.text.isEmpty
                    ? 'Empty'
                    : _terminalSeal1Controller.text,
                style: TextStyle(
                  color: _terminalSeal1Controller.text.isEmpty
                      ? Colors.grey
                      : AppTheme.successColor,
                ),
              ),
              onTap: () {
                _terminalSeal1Controller.text = scannedValue;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Terminal Seal 1: "$scannedValue"'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Text('2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: const Text('Terminal Seal 2'),
              subtitle: Text(
                _terminalSeal2Controller.text.isEmpty
                    ? 'Empty'
                    : _terminalSeal2Controller.text,
                style: TextStyle(
                  color: _terminalSeal2Controller.text.isEmpty
                      ? Colors.grey
                      : AppTheme.successColor,
                ),
              ),
              onTap: () {
                _terminalSeal2Controller.text = scannedValue;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Terminal Seal 2: "$scannedValue"'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDraft() async {
    // Check for duplicates before saving draft
    final isEditMode = widget.cmoData['isEditMode'] == true;
    final excludeId = isEditMode ? widget.cmoData['id']?.toString() : null;

    // Check for duplicate customer ID
    final customerId = widget.cmoData['customerId']?.toString();
    if (customerId != null && customerId.isNotEmpty) {
      final isCustomerDuplicate = await DatabaseService.instance.isCustomerIdDuplicate(
        customerId,
        excludeCmoId: excludeId,
      );
      if (isCustomerDuplicate && !isEditMode) {
        final existingCmo = await DatabaseService.instance.getCMOByCustomerId(customerId);
        if (mounted) {
          _showDuplicateError(
            'Duplicate Customer ID',
            'Customer $customerId already exists!\n'
            'Name: ${existingCmo?.customerName ?? "N/A"}\n'
            'Status: ${existingCmo?.status ?? "N/A"}\n\n'
            'Cannot save duplicate customer.',
          );
        }
        return;
      }
    }

    // Check for duplicate meter ID
    final newMeterId = widget.cmoData['newMeterId']?.toString();
    if (newMeterId != null && newMeterId.isNotEmpty) {
      final isMeterDuplicate = await DatabaseService.instance.isNewMeterIdDuplicate(
        newMeterId,
        excludeCmoId: excludeId,
      );
      if (isMeterDuplicate && !isEditMode) {
        final existingCmo = await DatabaseService.instance.getCMOByNewMeterId(newMeterId);
        if (mounted) {
          _showDuplicateError(
            'Duplicate Meter Number',
            'Meter $newMeterId already exists!\n'
            'Customer: ${existingCmo?.customerName ?? "N/A"}\n'
            'Status: ${existingCmo?.status ?? "N/A"}\n\n'
            'Cannot save duplicate meter.',
          );
        }
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Collect seal info data
      final sealInfoData = {
        'batteryCoverSeal': _batteryCoverSealController.text,
        'batteryCoverSealImagePath': _batteryCoverSealImagePath,
        'terminalSeal1': _terminalSeal1Controller.text,
        'terminalSeal2': _terminalSeal2Controller.text,
        'terminalCoverSealImagePath': _terminalCoverSealImagePath,
        'hasSteelBox': _hasSteelBox.toString(),
        'installBy': _installByController.text,
      };

      // Combine all data
      final completeData = {...widget.cmoData, ...sealInfoData};

      // Check if in edit mode
      final isEditMode = completeData['isEditMode'] == true;

      // Create CMO object
      final cmo = CMO(
        id: isEditMode ? completeData['id'] : null,
        customerId: completeData['customerId'],
        newMeterId: completeData['newMeterId'],
        customerName: completeData['customerName'] ?? '',
        flatNo: completeData['flatNo'],
        floor: completeData['floor'],
        mobileNumber: completeData['mobileNumber'] ?? '',
        secondaryMobileNumber: completeData['secondaryMobileNumber'],
        email: completeData['email'],
        nid: completeData['nid'],
        nocs: completeData['nocs'],
        feeder: completeData['feeder'],
        billGroup: completeData['billGroup'],
        sanctionLoad: completeData['sanctionLoad'],
        bookNumber: completeData['bookNumber'],
        tariff: completeData['tariff'],
        oldMeterType: completeData['oldMeterType'],
        oldMeterCategory: completeData['oldMeterCategory'],
        oldMeterNumber: completeData['oldMeterNumber'],
        oldMeterImagePath: completeData['oldMeterImagePath'],
        oldMeterReading: completeData['oldMeterReading'],
        onPeak: completeData['onPeak'],
        offPeak: completeData['offPeak'],
        kvar: completeData['kvar'],
        newMeterImagePath: completeData['newMeterImagePath'],
        newMeterLatitude: completeData['newMeterLatitude'] != null
            ? double.tryParse(completeData['newMeterLatitude'].toString())
            : null,
        newMeterLongitude: completeData['newMeterLongitude'] != null
            ? double.tryParse(completeData['newMeterLongitude'].toString())
            : null,
        installDate: _installDate,
        batteryCoverSeal: _batteryCoverSealController.text.isNotEmpty ? _batteryCoverSealController.text : null,
        batteryCoverSealImagePath: _batteryCoverSealImagePath,
        terminalSeal1: _terminalSeal1Controller.text.isNotEmpty ? _terminalSeal1Controller.text : null,
        terminalSeal2: _terminalSeal2Controller.text.isNotEmpty ? _terminalSeal2Controller.text : null,
        terminalCoverSealImagePath: _terminalCoverSealImagePath,
        hasSteelBox: _hasSteelBox,
        installBy: _installByController.text.isNotEmpty ? _installByController.text : null,
        status: 'draft',
      );

      // Save to database (update if edit mode, create if new)
      bool success;
      if (isEditMode) {
        success = await DatabaseService.instance.updateCMO(cmo);
      } else {
        final id = await DatabaseService.instance.createCMO(cmo);
        success = id != null;
      }

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEditMode ? 'Updated successfully' : 'Saved as draft'),
              backgroundColor: AppTheme.warningColor,
            ),
          );

          // Navigate back to CMO list screen
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEditMode ? 'Failed to update' : 'Failed to save draft'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving draft: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _handleUpload() async {
    if (_formKey.currentState!.validate()) {
      // Check for duplicates before uploading
      final isEditMode = widget.cmoData['isEditMode'] == true;
      final excludeId = isEditMode ? widget.cmoData['id']?.toString() : null;

      // Check for duplicate customer ID
      final customerId = widget.cmoData['customerId']?.toString();
      if (customerId != null && customerId.isNotEmpty) {
        final isCustomerDuplicate = await DatabaseService.instance.isCustomerIdDuplicate(
          customerId,
          excludeCmoId: excludeId,
        );
        if (isCustomerDuplicate && !isEditMode) {
          final existingCmo = await DatabaseService.instance.getCMOByCustomerId(customerId);
          if (mounted) {
            _showDuplicateError(
              'Duplicate Customer ID',
              'Customer $customerId already exists!\n'
              'Name: ${existingCmo?.customerName ?? "N/A"}\n'
              'Status: ${existingCmo?.status ?? "N/A"}',
            );
          }
          return;
        }
      }

      // Check for duplicate meter ID
      final newMeterId = widget.cmoData['newMeterId']?.toString();
      if (newMeterId != null && newMeterId.isNotEmpty) {
        final isMeterDuplicate = await DatabaseService.instance.isNewMeterIdDuplicate(
          newMeterId,
          excludeCmoId: excludeId,
        );
        if (isMeterDuplicate && !isEditMode) {
          final existingCmo = await DatabaseService.instance.getCMOByNewMeterId(newMeterId);
          if (mounted) {
            _showDuplicateError(
              'Duplicate Meter Number',
              'Meter $newMeterId already exists!\n'
              'Customer: ${existingCmo?.customerName ?? "N/A"}\n'
              'Status: ${existingCmo?.status ?? "N/A"}',
            );
          }
          return;
        }
      }

      setState(() => _isLoading = true);

      try {
        // Collect seal info data
        final sealInfoData = {
          'batteryCoverSeal': _batteryCoverSealController.text,
          'batteryCoverSealImagePath': _batteryCoverSealImagePath,
          'terminalSeal1': _terminalSeal1Controller.text,
          'terminalSeal2': _terminalSeal2Controller.text,
          'terminalCoverSealImagePath': _terminalCoverSealImagePath,
          'hasSteelBox': _hasSteelBox.toString(),
          'installBy': _installByController.text,
        };

        // Combine all data
        final completeData = {...widget.cmoData, ...sealInfoData};

        // Check if in edit mode
        final isEditMode = completeData['isEditMode'] == true;

        // Create CMO object
        final cmo = CMO(
          id: isEditMode ? completeData['id'] : null,
          customerId: completeData['customerId'],
          newMeterId: completeData['newMeterId'],
          customerName: completeData['customerName'] ?? '',
          flatNo: completeData['flatNo'],
          floor: completeData['floor'],
          mobileNumber: completeData['mobileNumber'] ?? '',
          secondaryMobileNumber: completeData['secondaryMobileNumber'],
          email: completeData['email'],
          nid: completeData['nid'],
          nocs: completeData['nocs'],
          feeder: completeData['feeder'],
          billGroup: completeData['billGroup'],
          sanctionLoad: completeData['sanctionLoad'],
          bookNumber: completeData['bookNumber'],
          tariff: completeData['tariff'],
          oldMeterType: completeData['oldMeterType'],
          oldMeterCategory: completeData['oldMeterCategory'],
          oldMeterNumber: completeData['oldMeterNumber'],
          oldMeterImagePath: completeData['oldMeterImagePath'],
          oldMeterReading: completeData['oldMeterReading'],
          onPeak: completeData['onPeak'],
          offPeak: completeData['offPeak'],
          kvar: completeData['kvar'],
          newMeterImagePath: completeData['newMeterImagePath'],
          newMeterLatitude: completeData['newMeterLatitude'] != null
              ? double.tryParse(completeData['newMeterLatitude'].toString())
              : null,
          newMeterLongitude: completeData['newMeterLongitude'] != null
              ? double.tryParse(completeData['newMeterLongitude'].toString())
              : null,
          installDate: _installDate,
          batteryCoverSeal: _batteryCoverSealController.text.isNotEmpty ? _batteryCoverSealController.text : null,
          batteryCoverSealImagePath: _batteryCoverSealImagePath,
          terminalSeal1: _terminalSeal1Controller.text.isNotEmpty ? _terminalSeal1Controller.text : null,
          terminalSeal2: _terminalSeal2Controller.text.isNotEmpty ? _terminalSeal2Controller.text : null,
          terminalCoverSealImagePath: _terminalCoverSealImagePath,
          hasSteelBox: _hasSteelBox,
          installBy: _installByController.text.isNotEmpty ? _installByController.text : null,
          status: 'uploaded',
        );

        // Save to database (update if edit mode, create if new)
        bool success;
        if (isEditMode) {
          success = await DatabaseService.instance.updateCMO(cmo);
        } else {
          final id = await DatabaseService.instance.createCMO(cmo);
          success = id != null;
        }

        if (mounted) {
          setState(() => _isLoading = false);

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isEditMode ? 'CMO updated successfully!' : 'CMO uploaded successfully!'),
                backgroundColor: AppTheme.successColor,
              ),
            );

            // Navigate back to CMO list screen
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isEditMode ? 'Failed to update CMO' : 'Failed to upload CMO'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error uploading CMO: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seal Info'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Title
                      _buildSectionTitle('Seal Information'),
                      const SizedBox(height: 16),

                      // QR Scanner Button for Seal Numbers
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withOpacity(0.1),
                              Colors.purple.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_scanner,
                                    color: AppTheme.primaryColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Scan Seal QR Code',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Scan QR and select seal field',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _scanSealQRCode,
                                icon: const Icon(Icons.qr_code_scanner, size: 20),
                                label: const Text('SCAN QR CODE'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Battery Cover Seal Section
                      _buildSectionTitle('Battery Cover Seal'),
                      const SizedBox(height: 16),

                      // Battery Cover Seal Image
                      if (_batteryCoverSealImagePath != null)
                        FutureBuilder<bool>(
                          future: File(_batteryCoverSealImagePath!).exists(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Container(
                                width: double.infinity,
                                height: 200,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.primaryColor, width: 2),
                                  color: Colors.grey.shade100,
                                ),
                                child: const Center(child: CircularProgressIndicator()),
                              );
                            }

                            if (snapshot.data == true) {
                              return Container(
                                width: double.infinity,
                                height: 200,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.primaryColor, width: 2),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(_batteryCoverSealImagePath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildImagePlaceholder('Image could not be loaded');
                                    },
                                  ),
                                ),
                              );
                            } else {
                              return Container(
                                width: double.infinity,
                                height: 120,
                                margin: const EdgeInsets.only(bottom: 16),
                                child: _buildImagePlaceholder('Previous image not found. Please retake photo.'),
                              );
                            }
                          },
                        ),

                      // Battery Seal Camera Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isCapturingBattery
                                  ? null
                                  : () => _captureImage(ImageSource.camera, 'battery'),
                              icon: const Icon(Icons.camera_alt, size: 20),
                              label: Text(
                                _batteryCoverSealImagePath == null ? 'Capture' : 'Retake',
                                style: const TextStyle(fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isCapturingBattery
                                  ? null
                                  : () => _captureImage(ImageSource.gallery, 'battery'),
                              icon: const Icon(Icons.photo_library, size: 20),
                              label: const Text('Gallery', style: TextStyle(fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                foregroundColor: AppTheme.primaryColor,
                                side: const BorderSide(color: AppTheme.primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Battery Cover Seal Number Input
                      TextFormField(
                        controller: _batteryCoverSealController,
                        decoration: InputDecoration(
                          labelText: 'Battery Cover Seal Number',
                          hintText: 'Enter or scan seal number',
                          prefixIcon: const Icon(Icons.label, color: AppTheme.primaryColor),
                          suffixIcon: _batteryCoverSealImagePath != null
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: _batteryCoverSealController.text.isNotEmpty,
                                      onChanged: null,
                                      activeColor: AppTheme.successColor,
                                    ),
                                  ],
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.text,
                      ),

                      const SizedBox(height: 32),

                      // Terminal Cover Seal Section
                      _buildSectionTitle('Terminal Cover Seal'),
                      const SizedBox(height: 16),

                      // Terminal Cover Seal Image
                      if (_terminalCoverSealImagePath != null)
                        FutureBuilder<bool>(
                          future: File(_terminalCoverSealImagePath!).exists(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Container(
                                width: double.infinity,
                                height: 200,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.primaryColor, width: 2),
                                  color: Colors.grey.shade100,
                                ),
                                child: const Center(child: CircularProgressIndicator()),
                              );
                            }

                            if (snapshot.data == true) {
                              return Container(
                                width: double.infinity,
                                height: 200,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.primaryColor, width: 2),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(_terminalCoverSealImagePath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildImagePlaceholder('Image could not be loaded');
                                    },
                                  ),
                                ),
                              );
                            } else {
                              return Container(
                                width: double.infinity,
                                height: 120,
                                margin: const EdgeInsets.only(bottom: 16),
                                child: _buildImagePlaceholder('Previous image not found. Please retake photo.'),
                              );
                            }
                          },
                        ),

                      // Terminal Seal Camera Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isCapturingTerminal
                                  ? null
                                  : () => _captureImage(ImageSource.camera, 'terminal'),
                              icon: const Icon(Icons.camera_alt, size: 20),
                              label: Text(
                                _terminalCoverSealImagePath == null ? 'Capture' : 'Retake',
                                style: const TextStyle(fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isCapturingTerminal
                                  ? null
                                  : () => _captureImage(ImageSource.gallery, 'terminal'),
                              icon: const Icon(Icons.photo_library, size: 20),
                              label: const Text('Gallery', style: TextStyle(fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                foregroundColor: AppTheme.primaryColor,
                                side: const BorderSide(color: AppTheme.primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Terminal Seal Numbers
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _terminalSeal1Controller,
                              decoration: InputDecoration(
                                labelText: 'Seal 1',
                                hintText: 'Seal 1 number',
                                prefixIcon: const Icon(Icons.label_outline,
                                    color: AppTheme.primaryColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.text,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _terminalSeal2Controller,
                              decoration: InputDecoration(
                                labelText: 'Seal 2',
                                hintText: 'Seal 2 number',
                                prefixIcon: const Icon(Icons.label_outline,
                                    color: AppTheme.primaryColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.text,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Steel Box Question
                      _buildSectionTitle('Additional Information'),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined,
                                color: AppTheme.primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Steel box over meter?',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: _hasSteelBox,
                              onChanged: (value) {
                                setState(() {
                                  _hasSteelBox = value;
                                });
                              },
                              activeTrackColor: AppTheme.primaryColor,
                            ),
                            SizedBox(
                              width: 30,
                              child: Text(
                                _hasSteelBox ? 'Yes' : 'No',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _hasSteelBox
                                      ? AppTheme.primaryColor
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Installation Date Picker
                      GestureDetector(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _installDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AppTheme.primaryColor,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: AppTheme.textPrimary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null && picked != _installDate) {
                            setState(() {
                              _installDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: AppTheme.primaryColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Installation Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('MMM dd, yyyy').format(_installDate),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Install By
                      TextFormField(
                        controller: _installByController,
                        decoration: InputDecoration(
                          labelText: 'Install By',
                          hintText: 'Installer name',
                          prefixIcon: const Icon(Icons.person, color: AppTheme.primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        enabled: false,
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Action Buttons
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      children: [
                        // PREVIOUS Button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(
                                color: AppTheme.primaryColor,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'PREVIOUS',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // DRAFT Button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _handleDraft,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(
                                color: AppTheme.warningColor,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'DRAFT',
                              style: TextStyle(
                                color: AppTheme.warningColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // UPLOAD Button
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _handleUpload,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppTheme.successColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'UPLOAD',
                              style: TextStyle(
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

  void _showDuplicateError(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorColor),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(color: AppTheme.errorColor))),
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

  Widget _buildImagePlaceholder(String message) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.warningColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
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
}
