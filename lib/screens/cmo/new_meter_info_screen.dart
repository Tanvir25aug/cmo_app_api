import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/app_theme.dart';
import '../../services/database_service.dart';
import '../../services/ocr_service.dart';
import '../../models/cmo_model.dart';
import 'seal_info_screen.dart';

class NewMeterInfoScreen extends StatefulWidget {
  final Map<String, dynamic> cmoData;

  const NewMeterInfoScreen({super.key, required this.cmoData});

  @override
  State<NewMeterInfoScreen> createState() => _NewMeterInfoScreenState();
}

class _NewMeterInfoScreenState extends State<NewMeterInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newMeterNumberController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _newMeterImagePath;
  double? _latitude;
  double? _longitude;
  bool _isCapturing = false;
  bool _isProcessingOcr = false;
  bool _isGettingLocation = false;
  String? _ocrStatus;
  bool? _isMeterNumberMatched; // null = not validated, true = matched, false = not matched

  // QR scanned meter number from Add CMO screen (page 1)
  String? get _qrMeterNumber => widget.cmoData['newMeterId']?.toString();

  @override
  void initState() {
    super.initState();
    // Pre-fill data if in edit mode
    if (widget.cmoData['isEditMode'] == true) {
      _newMeterNumberController.text = widget.cmoData['newMeterId'] ?? '';
      _newMeterImagePath = widget.cmoData['newMeterImagePath'];
      _latitude = widget.cmoData['newMeterLatitude'] != null
          ? double.tryParse(widget.cmoData['newMeterLatitude'].toString())
          : null;
      _longitude = widget.cmoData['newMeterLongitude'] != null
          ? double.tryParse(widget.cmoData['newMeterLongitude'].toString())
          : null;
      // Validate if we already have OCR data in edit mode
      if (_newMeterNumberController.text.isNotEmpty) {
        _validateMeterNumbers();
      }
    }
  }

  @override
  void dispose() {
    _newMeterNumberController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      // Check if location services are enabled
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

      // Check location permissions
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
              content: Text('Location permissions are permanently denied. Please enable from settings.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
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
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _captureImage(ImageSource source) async {
    try {
      setState(() => _isCapturing = true);

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null && mounted) {
        setState(() {
          _newMeterImagePath = image.path;
          _isCapturing = false;
          _isProcessingOcr = true;
          _ocrStatus = 'Processing image...';
        });

        // Get location automatically when taking photo
        await _getCurrentLocation();

        // Process OCR
        await _processOcr(image.path);
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
        setState(() {
          _isCapturing = false;
          _isProcessingOcr = false;
          _ocrStatus = null;
        });
      }
    }
  }

  Future<void> _processOcr(String imagePath) async {
    try {
      setState(() {
        _ocrStatus = 'Recognizing meter number...';
      });

      final result = await OcrService.instance.extractMeterReading(imagePath);

      if (!mounted) return;

      if (result.success && result.allLines != null) {
        // Look for 8-digit number starting with 7, 8, or 9
        String? newMeterNumber = _extractNewMeterNumber(result.allLines!, result.rawText ?? '');

        if (newMeterNumber != null) {
          _newMeterNumberController.text = newMeterNumber;
          // Validate against QR number from page 1
          _validateMeterNumbers();
          _showOcrResultDialog(newMeterNumber);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not find 8-digit meter number starting with 7, 8, or 9. Please enter manually.'),
              backgroundColor: AppTheme.warningColor,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Could not recognize text. Please enter values manually.'),
            backgroundColor: AppTheme.warningColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Extract 8-digit meter number starting with 7, 8, or 9
  String? _extractNewMeterNumber(List<String> lines, String allText) {
    // Pattern for 8-digit number starting with 7, 8, or 9
    final meterPattern = RegExp(r'\b([789]\d{7})\b');

    // First check all lines
    for (String line in lines) {
      final match = meterPattern.firstMatch(line);
      if (match != null) {
        return match.group(1);
      }
    }

    // Check entire text
    final matches = meterPattern.allMatches(allText).toList();
    if (matches.isNotEmpty) {
      return matches.first.group(1);
    }

    return null;
  }

  /// Validate if OCR meter number matches QR scanned meter number from page 1
  void _validateMeterNumbers() {
    final ocrNumber = _newMeterNumberController.text.trim();
    final qrNumber = _qrMeterNumber?.trim();

    if (ocrNumber.isEmpty || qrNumber == null || qrNumber.isEmpty) {
      setState(() {
        _isMeterNumberMatched = null;
      });
      return;
    }

    final isMatched = ocrNumber == qrNumber;
    setState(() {
      _isMeterNumberMatched = isMatched;
    });
  }

  void _showOcrResultDialog(String meterNumber) {
    final isMatched = meterNumber == _qrMeterNumber;

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
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.document_scanner,
                    color: isMatched ? AppTheme.successColor : AppTheme.errorColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'New Meter Number Detected',
                      style: TextStyle(
                        fontSize: 20,
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
              const SizedBox(height: 16),

              // OCR Result
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.camera_alt, color: Colors.blue, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'OCR Meter Number (from Photo)',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            meterNumber,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // QR Number from Page 1
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code, color: Colors.purple, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'QR Meter Number (from Add CMO)',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _qrMeterNumber ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Validation Result
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isMatched
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isMatched ? AppTheme.successColor : AppTheme.errorColor,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isMatched ? Icons.check_circle : Icons.cancel,
                      color: isMatched ? AppTheme.successColor : AppTheme.errorColor,
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMatched ? 'MATCHED!' : 'NOT MATCHED!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isMatched ? AppTheme.successColor : AppTheme.errorColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isMatched
                                ? 'OCR and QR numbers match. You can proceed.'
                                : 'Numbers do not match. Please retake photo or check meter.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isMatched ? AppTheme.successColor : AppTheme.errorColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: isMatched ? AppTheme.successColor : AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(isMatched ? 'Continue' : 'OK'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleDraft() async {
    try {
      final isEditMode = widget.cmoData['isEditMode'] == true;

      // Update newMeterId with the captured number
      final updatedCmoData = {
        ...widget.cmoData,
        'newMeterId': _newMeterNumberController.text.isNotEmpty
            ? _newMeterNumberController.text
            : widget.cmoData['newMeterId'],
        'newMeterImagePath': _newMeterImagePath,
        'newMeterLatitude': _latitude,
        'newMeterLongitude': _longitude,
      };

      final cmo = CMO(
        id: isEditMode ? updatedCmoData['id'] : null,
        customerId: updatedCmoData['customerId'],
        newMeterId: updatedCmoData['newMeterId'],
        customerName: updatedCmoData['customerName'] ?? '',
        flatNo: updatedCmoData['flatNo'],
        floor: updatedCmoData['floor'],
        mobileNumber: updatedCmoData['mobileNumber'] ?? '',
        secondaryMobileNumber: updatedCmoData['secondaryMobileNumber'],
        email: updatedCmoData['email'],
        nid: updatedCmoData['nid'],
        nocs: updatedCmoData['nocs'],
        feeder: updatedCmoData['feeder'],
        billGroup: updatedCmoData['billGroup'],
        sanctionLoad: updatedCmoData['sanctionLoad'],
        bookNumber: updatedCmoData['bookNumber'],
        tariff: updatedCmoData['tariff'],
        oldMeterType: updatedCmoData['oldMeterType'],
        oldMeterCategory: updatedCmoData['oldMeterCategory'],
        oldMeterNumber: updatedCmoData['oldMeterNumber'],
        oldMeterImagePath: updatedCmoData['oldMeterImagePath'],
        oldMeterReading: updatedCmoData['oldMeterReading'],
        onPeak: updatedCmoData['onPeak'],
        offPeak: updatedCmoData['offPeak'],
        kvar: updatedCmoData['kvar'],
        newMeterImagePath: _newMeterImagePath,
        newMeterLatitude: _latitude,
        newMeterLongitude: _longitude,
        batteryCoverSeal: isEditMode ? updatedCmoData['batteryCoverSeal'] : null,
        batteryCoverSealImagePath: isEditMode ? updatedCmoData['batteryCoverSealImagePath'] : null,
        terminalSeal1: isEditMode ? updatedCmoData['terminalSeal1'] : null,
        terminalSeal2: isEditMode ? updatedCmoData['terminalSeal2'] : null,
        terminalCoverSealImagePath: isEditMode ? updatedCmoData['terminalCoverSealImagePath'] : null,
        hasSteelBox: isEditMode ? (updatedCmoData['hasSteelBox'] ?? false) : false,
        installBy: isEditMode ? updatedCmoData['installBy'] : null,
        status: 'draft',
      );

      bool success;
      if (isEditMode) {
        success = await DatabaseService.instance.updateCMO(cmo);
      } else {
        final id = await DatabaseService.instance.createCMO(cmo);
        success = id != null;
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode ? 'Updated successfully!' : 'Saved as draft successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        throw Exception(isEditMode ? 'Failed to update' : 'Failed to save draft');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving draft: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _handleNext() async {
    if (_formKey.currentState!.validate()) {
      // Validate that meter numbers match
      if (_isMeterNumberMatched != true) {
        final ocrNumber = _newMeterNumberController.text.trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Meter numbers do not match!\nOCR (Photo): $ocrNumber\nQR (Add CMO): $_qrMeterNumber\n\nPlease retake photo.',
            ),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Update the data with new meter info
      final newMeterData = {
        'newMeterId': _newMeterNumberController.text.isNotEmpty
            ? _newMeterNumberController.text
            : widget.cmoData['newMeterId'],
        'newMeterImagePath': _newMeterImagePath,
        'newMeterLatitude': _latitude,
        'newMeterLongitude': _longitude,
      };

      final combinedData = {...widget.cmoData, ...newMeterData};

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SealInfoScreen(cmoData: combinedData),
        ),
      );

      if (result != null && mounted) {
        Navigator.of(context).pop(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Meter Info'),
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
                      // Show QR Meter Number from Page 1
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.qr_code, color: Colors.purple, size: 32),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'QR Meter Number (from Add CMO)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _qrMeterNumber ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildSectionTitle('New Meter Photo'),
                      const SizedBox(height: 16),

                      // Info Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Take a photo of the new meter. OCR will extract meter number and validate against QR number.',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Image Preview
                      if (_newMeterImagePath != null)
                        Container(
                          width: double.infinity,
                          height: 250,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primaryColor, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(_newMeterImagePath!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                      // Camera Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: (_isCapturing || _isProcessingOcr)
                                  ? null
                                  : () => _captureImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: Text(_newMeterImagePath == null ? 'Take Photo' : 'Retake Photo'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: (_isCapturing || _isProcessingOcr)
                                  ? null
                                  : () => _captureImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Gallery'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
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

                      if (_isCapturing || _isProcessingOcr || _isGettingLocation) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _ocrStatus ?? (_isGettingLocation ? 'Getting location...' : (_isCapturing ? 'Capturing...' : 'Processing...')),
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // OCR Meter Number
                      _buildSectionTitle('OCR Meter Number (from Photo)'),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _newMeterNumberController,
                        decoration: InputDecoration(
                          labelText: 'New Meter Number (OCR) *',
                          hintText: 'Will be extracted from photo',
                          prefixIcon: const Icon(Icons.electric_meter, color: AppTheme.primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          // Re-validate when OCR number changes
                          _validateMeterNumbers();
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please take photo to extract meter number';
                          }
                          if (value.length != 8) {
                            return 'Meter number must be 8 digits';
                          }
                          if (!RegExp(r'^[789]\d{7}$').hasMatch(value)) {
                            return 'Meter number must start with 7, 8, or 9';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Validation Status
                      if (_isMeterNumberMatched != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isMeterNumberMatched!
                                ? AppTheme.successColor.withOpacity(0.1)
                                : AppTheme.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isMeterNumberMatched! ? AppTheme.successColor : AppTheme.errorColor,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isMeterNumberMatched! ? Icons.check_circle : Icons.cancel,
                                color: _isMeterNumberMatched! ? AppTheme.successColor : AppTheme.errorColor,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isMeterNumberMatched! ? 'MATCHED' : 'NOT MATCHED',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _isMeterNumberMatched! ? AppTheme.successColor : AppTheme.errorColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isMeterNumberMatched!
                                          ? 'OCR and QR numbers match. You can proceed.'
                                          : 'OCR: ${_newMeterNumberController.text}\nQR: $_qrMeterNumber\n\nPlease retake photo.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _isMeterNumberMatched! ? AppTheme.successColor : AppTheme.errorColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // GPS Location Section (Auto-captured, display only)
                      _buildSectionTitle('GPS Location (Auto-captured)'),
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
                            Icon(
                              _latitude != null ? Icons.location_on : Icons.location_off,
                              color: _latitude != null ? AppTheme.successColor : AppTheme.textSecondary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _latitude != null ? 'Location Captured' : 'No Location Yet',
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
                                      'Lat: ${_latitude!.toStringAsFixed(6)}',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                    ),
                                    Text(
                                      'Lng: ${_longitude!.toStringAsFixed(6)}',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Location will be captured when you take photo',
                                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
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
                    color: Colors.black.withOpacity(0.05),
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
                        side: const BorderSide(color: AppTheme.primaryColor, width: 2),
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
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _handleDraft,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppTheme.warningColor, width: 2),
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
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleNext,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'NEXT',
                        style: TextStyle(fontWeight: FontWeight.bold),
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
