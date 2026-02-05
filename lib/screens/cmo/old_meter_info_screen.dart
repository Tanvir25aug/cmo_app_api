import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/app_theme.dart';
import '../../services/database_service.dart';
import '../../services/ocr_service.dart';
import '../../models/cmo_model.dart';
import 'new_meter_info_screen.dart';

class OldMeterInfoScreen extends StatefulWidget {
  final Map<String, dynamic> cmoData;

  const OldMeterInfoScreen({super.key, required this.cmoData});

  @override
  State<OldMeterInfoScreen> createState() => _OldMeterInfoScreenState();
}

class _OldMeterInfoScreenState extends State<OldMeterInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _meterNumberController = TextEditingController();
  final _oldMeterReadingController = TextEditingController();
  final _onPeakController = TextEditingController();
  final _offPeakController = TextEditingController();
  final _kvarController = TextEditingController();
  final _takaController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _selectedMeterType;
  String? _selectedMeterCategory; // postpaid or prepaid
  String? _oldMeterImagePath;
  bool _isCapturing = false;
  bool _isProcessingOcr = false;
  String? _ocrStatus;
  bool? _isOldMeterNumberMatched; // null = not validated, true = matched, false = not matched

  final List<String> _meterTypes = ['1P', '3P'];
  final List<String> _meterCategories = ['postpaid', 'prepaid'];

  // Fetched old meter number from customer data
  String? get _fetchedOldMeterNumber => widget.cmoData['fetchedOldMeterNumber']?.toString();

  @override
  void initState() {
    super.initState();
    if (widget.cmoData['isEditMode'] == true) {
      _selectedMeterType = widget.cmoData['oldMeterType'];
      _selectedMeterCategory = widget.cmoData['oldMeterCategory'] ?? 'postpaid';
      _meterNumberController.text = widget.cmoData['oldMeterNumber'] ?? '';
      _oldMeterImagePath = widget.cmoData['oldMeterImagePath'];

      // For prepaid, oldMeterReading contains taka value
      if (_selectedMeterCategory == 'prepaid') {
        _takaController.text = widget.cmoData['oldMeterReading'] ?? '';
      } else {
        _oldMeterReadingController.text = widget.cmoData['oldMeterReading'] ?? '';
        _onPeakController.text = widget.cmoData['onPeak'] ?? '';
        _offPeakController.text = widget.cmoData['offPeak'] ?? '';
        _kvarController.text = widget.cmoData['kvar'] ?? '';
      }

      // Validate if meter number already exists
      if (_meterNumberController.text.isNotEmpty) {
        _validateOldMeterNumber();
      }
    } else {
      // Default to postpaid for new entries
      _selectedMeterCategory = 'postpaid';
    }
  }

  @override
  void dispose() {
    _meterNumberController.dispose();
    _oldMeterReadingController.dispose();
    _onPeakController.dispose();
    _offPeakController.dispose();
    _kvarController.dispose();
    _takaController.dispose();
    super.dispose();
  }

  /// Validate if OCR old meter number matches fetched old meter number
  void _validateOldMeterNumber() {
    final ocrNumber = _meterNumberController.text.trim();
    final fetchedNumber = _fetchedOldMeterNumber?.trim();

    if (ocrNumber.isEmpty || fetchedNumber == null || fetchedNumber.isEmpty) {
      setState(() {
        _isOldMeterNumberMatched = null;
      });
      return;
    }

    final isMatched = ocrNumber == fetchedNumber;
    setState(() {
      _isOldMeterNumberMatched = isMatched;
    });
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
          _oldMeterImagePath = image.path;
          _isCapturing = false;
          _isProcessingOcr = true;
          _ocrStatus = 'Processing image...';
        });

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
        _ocrStatus = 'Recognizing text...';
      });

      final result = await OcrService.instance.extractMeterReading(imagePath);

      if (!mounted) return;

      if (result.success) {
        // Auto-fill the detected values
        if (result.meterNumber != null && result.meterNumber!.isNotEmpty) {
          _meterNumberController.text = result.meterNumber!;
          // Validate against fetched old meter number
          _validateOldMeterNumber();
        }
        if (result.meterReading != null && result.meterReading!.isNotEmpty) {
          _oldMeterReadingController.text = result.meterReading!;
        }
        if (result.onPeak != null && result.onPeak!.isNotEmpty) {
          _onPeakController.text = result.onPeak!;
        }
        if (result.offPeak != null && result.offPeak!.isNotEmpty) {
          _offPeakController.text = result.offPeak!;
        }
        if (result.kvar != null && result.kvar!.isNotEmpty) {
          _kvarController.text = result.kvar!;
        }

        // Show OCR results dialog
        _showOcrResultsDialog(result);
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

  void _showOcrResultsDialog(MeterOcrResult result) {
    final isMatched = _meterNumberController.text.trim() == _fetchedOldMeterNumber?.trim();

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
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.document_scanner,
                    color: isMatched ? AppTheme.successColor : AppTheme.warningColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'OCR Results',
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
              const SizedBox(height: 8),

              // Validation Status for Old Meter Number
              if (_fetchedOldMeterNumber != null && _fetchedOldMeterNumber!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMatched
                        ? AppTheme.successColor.withOpacity(0.1)
                        : AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isMatched ? AppTheme.successColor : AppTheme.errorColor,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            isMatched ? Icons.check_circle : Icons.warning,
                            color: isMatched ? AppTheme.successColor : AppTheme.errorColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isMatched ? 'OLD METER NUMBER MATCHED!' : 'OLD METER NUMBER NOT MATCHED!',
                              style: TextStyle(
                                color: isMatched ? AppTheme.successColor : AppTheme.errorColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Fetched:', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                Text(
                                  _fetchedOldMeterNumber!,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('OCR:', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                Text(
                                  result.meterNumber ?? 'N/A',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!isMatched) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Please verify and enter the correct meter number manually if needed.',
                          style: TextStyle(fontSize: 12, color: AppTheme.errorColor),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (result.meterNumber != null) ...[
                        _buildOcrResultItem('Meter Number', result.meterNumber!, Icons.pin),
                        const SizedBox(height: 12),
                      ],
                      if (result.meterReading != null) ...[
                        _buildOcrResultItem('Meter Reading', result.meterReading!, Icons.speed),
                        const SizedBox(height: 12),
                      ],
                      if (result.onPeak != null) ...[
                        _buildOcrResultItem('On-Peak', result.onPeak!, Icons.wb_sunny),
                        const SizedBox(height: 12),
                      ],
                      if (result.offPeak != null) ...[
                        _buildOcrResultItem('Off-Peak', result.offPeak!, Icons.nightlight),
                        const SizedBox(height: 12),
                      ],
                      if (result.kvar != null) ...[
                        _buildOcrResultItem('KVAR', result.kvar!, Icons.bolt),
                        const SizedBox(height: 12),
                      ],
                      if (result.allLines != null && result.allLines!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'All Detected Text:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: result.allLines!.take(15).map((line) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: InkWell(
                                  onTap: () => _selectOcrValue(line),
                                  child: Text(
                                    line,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOcrResultItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
        ],
      ),
    );
  }

  void _selectOcrValue(String value) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Use this value for:'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.pin),
              title: const Text('Meter Number'),
              onTap: () {
                _meterNumberController.text = value;
                _validateOldMeterNumber();
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.speed),
              title: const Text('Meter Reading'),
              onTap: () {
                _oldMeterReadingController.text = value;
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.wb_sunny),
              title: const Text('On-Peak'),
              onTap: () {
                _onPeakController.text = value;
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.nightlight),
              title: const Text('Off-Peak'),
              onTap: () {
                _offPeakController.text = value;
                Navigator.pop(context);
                Navigator.pop(context);
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
    try {
      final isEditMode = widget.cmoData['isEditMode'] == true;

      // For prepaid, store taka in oldMeterReading; for postpaid, store actual reading
      final oldMeterReading = _selectedMeterCategory == 'prepaid'
          ? (_takaController.text.isNotEmpty ? _takaController.text : null)
          : (_oldMeterReadingController.text.isNotEmpty ? _oldMeterReadingController.text : null);

      final cmo = CMO(
        id: isEditMode ? widget.cmoData['id'] : null,
        customerId: widget.cmoData['customerId'],
        newMeterId: widget.cmoData['newMeterId'],
        customerName: widget.cmoData['customerName'] ?? '',
        flatNo: widget.cmoData['flatNo'],
        floor: widget.cmoData['floor'],
        mobileNumber: widget.cmoData['mobileNumber'] ?? '',
        secondaryMobileNumber: widget.cmoData['secondaryMobileNumber'],
        email: widget.cmoData['email'],
        nid: widget.cmoData['nid'],
        nocs: widget.cmoData['nocs'],
        feeder: widget.cmoData['feeder'],
        billGroup: widget.cmoData['billGroup'],
        sanctionLoad: widget.cmoData['sanctionLoad'],
        bookNumber: widget.cmoData['bookNumber'],
        tariff: widget.cmoData['tariff'],
        oldMeterType: _selectedMeterType,
        oldMeterCategory: _selectedMeterCategory,
        oldMeterNumber: _meterNumberController.text.isNotEmpty ? _meterNumberController.text : null,
        oldMeterImagePath: _oldMeterImagePath,
        oldMeterReading: oldMeterReading,
        onPeak: _selectedMeterCategory == 'postpaid' && _onPeakController.text.isNotEmpty
            ? _onPeakController.text
            : null,
        offPeak: _selectedMeterCategory == 'postpaid' && _offPeakController.text.isNotEmpty
            ? _offPeakController.text
            : null,
        kvar: _selectedMeterCategory == 'postpaid' && _kvarController.text.isNotEmpty
            ? _kvarController.text
            : null,
        newMeterImagePath: isEditMode ? widget.cmoData['newMeterImagePath'] : null,
        newMeterLatitude: isEditMode ? widget.cmoData['newMeterLatitude'] : null,
        newMeterLongitude: isEditMode ? widget.cmoData['newMeterLongitude'] : null,
        batteryCoverSeal: isEditMode ? widget.cmoData['batteryCoverSeal'] : null,
        batteryCoverSealImagePath: isEditMode ? widget.cmoData['batteryCoverSealImagePath'] : null,
        terminalSeal1: isEditMode ? widget.cmoData['terminalSeal1'] : null,
        terminalSeal2: isEditMode ? widget.cmoData['terminalSeal2'] : null,
        terminalCoverSealImagePath: isEditMode ? widget.cmoData['terminalCoverSealImagePath'] : null,
        hasSteelBox: isEditMode ? (widget.cmoData['hasSteelBox'] ?? false) : false,
        installBy: isEditMode ? widget.cmoData['installBy'] : null,
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
        Navigator.of(context).pop();
        Navigator.of(context).pop();
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
      // For prepaid, store taka in oldMeterReading; for postpaid, store actual reading
      final oldMeterReading = _selectedMeterCategory == 'prepaid'
          ? _takaController.text
          : _oldMeterReadingController.text;

      final oldMeterData = {
        'oldMeterType': _selectedMeterType,
        'oldMeterCategory': _selectedMeterCategory,
        'oldMeterNumber': _meterNumberController.text,
        'oldMeterImagePath': _oldMeterImagePath,
        'oldMeterReading': oldMeterReading,
        'onPeak': _selectedMeterCategory == 'postpaid' ? _onPeakController.text : null,
        'offPeak': _selectedMeterCategory == 'postpaid' ? _offPeakController.text : null,
        'kvar': _selectedMeterCategory == 'postpaid' ? _kvarController.text : null,
      };

      final combinedData = {...widget.cmoData, ...oldMeterData};

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NewMeterInfoScreen(cmoData: combinedData),
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
        title: const Text('Old Meter Info'),
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
                      // Show Fetched Old Meter Number from Customer Data
                      if (_fetchedOldMeterNumber != null && _fetchedOldMeterNumber!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purple.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.electric_meter, color: Colors.purple, size: 32),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Old Meter Number (from Customer Data)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _fetchedOldMeterNumber!,
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
                      ],

                      _buildSectionTitle('Old Meter Information'),
                      const SizedBox(height: 20),

                      // Meter Type Dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Meter Type *',
                          hintText: 'Select meter type',
                          prefixIcon: const Icon(Icons.electric_meter, color: AppTheme.primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        value: _selectedMeterType,
                        items: _meterTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type == '1P' ? '1P (Single Phase)' : '3P (Three Phase)'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMeterType = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select meter type';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Meter Category Dropdown (Postpaid/Prepaid)
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Meter Category *',
                          hintText: 'Select meter category',
                          prefixIcon: const Icon(Icons.category, color: AppTheme.primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        value: _selectedMeterCategory,
                        items: _meterCategories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category == 'postpaid' ? 'Postpaid' : 'Prepaid'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMeterCategory = value;
                            // Clear the other fields when switching category
                            if (value == 'prepaid') {
                              _oldMeterReadingController.clear();
                              _onPeakController.clear();
                              _offPeakController.clear();
                              _kvarController.clear();
                            } else {
                              _takaController.clear();
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select meter category';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Camera Section
                      _buildSectionTitle('Capture Old Meter'),
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
                                'Take photo to extract meter number via OCR. It will be validated against customer data.',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Image Preview
                      if (_oldMeterImagePath != null)
                        FutureBuilder<bool>(
                          future: File(_oldMeterImagePath!).exists(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Container(
                                width: double.infinity,
                                height: 250,
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
                                height: 250,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.primaryColor, width: 2),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(_oldMeterImagePath!),
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
                                height: 150,
                                margin: const EdgeInsets.only(bottom: 16),
                                child: _buildImagePlaceholder('Previous image not found. Please retake photo.'),
                              );
                            }
                          },
                        ),

                      // Camera Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: (_isCapturing || _isProcessingOcr) ? null : () => _captureImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: Text(_oldMeterImagePath == null ? 'Take Photo' : 'Retake Photo'),
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
                              onPressed: (_isCapturing || _isProcessingOcr) ? null : () => _captureImage(ImageSource.gallery),
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

                      if (_isCapturing || _isProcessingOcr) ...[
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
                                _ocrStatus ?? (_isCapturing ? 'Capturing...' : 'Processing...'),
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

                      // Meter Number Input
                      _buildSectionTitle('Meter Number (OCR)'),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _meterNumberController,
                        decoration: InputDecoration(
                          labelText: 'Old Meter Number *',
                          hintText: 'Enter meter number',
                          prefixIcon: const Icon(Icons.pin, color: AppTheme.primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.text,
                        onChanged: (value) {
                          _validateOldMeterNumber();
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter meter number';
                          }
                          return null;
                        },
                      ),

                      // Validation Status
                      if (_isOldMeterNumberMatched != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isOldMeterNumberMatched!
                                ? AppTheme.successColor.withOpacity(0.1)
                                : AppTheme.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isOldMeterNumberMatched! ? AppTheme.successColor : AppTheme.errorColor,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isOldMeterNumberMatched! ? Icons.check_circle : Icons.cancel,
                                color: _isOldMeterNumberMatched! ? AppTheme.successColor : AppTheme.errorColor,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isOldMeterNumberMatched! ? 'MATCHED' : 'NOT MATCHED',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _isOldMeterNumberMatched! ? AppTheme.successColor : AppTheme.errorColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isOldMeterNumberMatched!
                                          ? 'OCR number matches customer data.'
                                          : 'OCR: ${_meterNumberController.text}\nFetched: $_fetchedOldMeterNumber\n\nPlease verify manually.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _isOldMeterNumberMatched! ? AppTheme.successColor : AppTheme.errorColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Meter Reading Section - Conditional based on category
                      _buildSectionTitle(_selectedMeterCategory == 'prepaid' ? 'Balance Information' : 'Meter Readings'),
                      const SizedBox(height: 16),

                      if (_selectedMeterCategory == 'prepaid') ...[
                        // Prepaid: Show only Taka input
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'For prepaid meters, enter the remaining balance (Taka).',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _takaController,
                          decoration: InputDecoration(
                            labelText: 'Balance (Taka) *',
                            hintText: 'Enter remaining balance in Taka',
                            prefixIcon: const Icon(Icons.attach_money, color: AppTheme.primaryColor),
                            suffixText: 'BDT',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter balance amount';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        // Postpaid: Show meter reading fields
                        // Old Meter Reading
                        TextFormField(
                          controller: _oldMeterReadingController,
                          decoration: InputDecoration(
                            labelText: 'Old Meter Reading',
                            hintText: 'Enter old meter reading manually',
                            prefixIcon: const Icon(Icons.speed, color: AppTheme.primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),

                        const SizedBox(height: 16),

                        // On-Peak and Off-Peak
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _onPeakController,
                                decoration: InputDecoration(
                                  labelText: 'On-Peak',
                                  hintText: 'On-peak reading',
                                  prefixIcon: const Icon(Icons.wb_sunny, color: AppTheme.primaryColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _offPeakController,
                                decoration: InputDecoration(
                                  labelText: 'Off-Peak',
                                  hintText: 'Off-peak reading',
                                  prefixIcon: const Icon(Icons.nightlight, color: AppTheme.primaryColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // KVAR
                        TextFormField(
                          controller: _kvarController,
                          decoration: InputDecoration(
                            labelText: 'KVAR',
                            hintText: 'Enter KVAR value',
                            prefixIcon: const Icon(Icons.bolt, color: AppTheme.primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],

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
            size: 48,
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
                fontSize: 13,
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
