import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../services/database_service.dart';
import '../../services/customer_api_service.dart';
import '../../models/cmo_model.dart';
import '../../models/customer_model.dart';
import 'barcode_scanner_screen.dart';
import 'old_meter_info_screen.dart';

class AddCMOScreen extends StatefulWidget {
  final Map<String, dynamic>? cmoData;

  const AddCMOScreen({super.key, this.cmoData});

  @override
  State<AddCMOScreen> createState() => _AddCMOScreenState();
}

class _AddCMOScreenState extends State<AddCMOScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final _customerIdController = TextEditingController();
  final _newMeterController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _flatNoController = TextEditingController();
  final _floorController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _secondaryMobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _nidController = TextEditingController();
  final _nocsController = TextEditingController();
  final _feederController = TextEditingController();
  final _billGroupController = TextEditingController();
  final _sanctionLoadController = TextEditingController();
  final _bookNumberController = TextEditingController();
  final _tariffController = TextEditingController();

  bool _isLoading = false;
  bool _isSearching = false;
  Customer? _foundCustomer;
  bool _isDuplicateCustomer = false;
  String? _duplicateMessage;
  bool _isDuplicateMeter = false;
  String? _duplicateMeterMessage;

  @override
  void initState() {
    super.initState();
    // Pre-fill data if in edit mode
    if (widget.cmoData != null) {
      _customerIdController.text = widget.cmoData!['customerId'] ?? '';
      _newMeterController.text = widget.cmoData!['newMeterId'] ?? '';
      _customerNameController.text = widget.cmoData!['customerName'] ?? '';
      _flatNoController.text = widget.cmoData!['flatNo'] ?? '';
      _floorController.text = widget.cmoData!['floor'] ?? '';
      _mobileNumberController.text = widget.cmoData!['mobileNumber'] ?? '';
      _secondaryMobileController.text = widget.cmoData!['secondaryMobileNumber'] ?? '';
      _emailController.text = widget.cmoData!['email'] ?? '';
      _nidController.text = widget.cmoData!['nid'] ?? '';
      _nocsController.text = widget.cmoData!['nocs'] ?? '';
      _feederController.text = widget.cmoData!['feeder'] ?? '';
      _billGroupController.text = widget.cmoData!['billGroup'] ?? '';
      _sanctionLoadController.text = widget.cmoData!['sanctionLoad'] ?? '';
      _bookNumberController.text = widget.cmoData!['bookNumber'] ?? '';
      _tariffController.text = widget.cmoData!['tariff'] ?? '';
    }
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    _newMeterController.dispose();
    _customerNameController.dispose();
    _flatNoController.dispose();
    _floorController.dispose();
    _mobileNumberController.dispose();
    _secondaryMobileController.dispose();
    _emailController.dispose();
    _nidController.dispose();
    _nocsController.dispose();
    _feederController.dispose();
    _billGroupController.dispose();
    _sanctionLoadController.dispose();
    _bookNumberController.dispose();
    _tariffController.dispose();
    super.dispose();
  }

  void _handleNext() async {
    // Check for duplicate customer
    if (_isDuplicateCustomer) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_duplicateMessage ?? 'Cannot proceed. Customer already has meter installed!'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // Check for duplicate meter
    if (_isDuplicateMeter) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_duplicateMeterMessage ?? 'Cannot proceed. Meter number already exists!'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Collect CMO data
      final cmoData = {
        'customerId': _customerIdController.text,
        'newMeterId': _newMeterController.text,
        'customerName': _customerNameController.text,
        'flatNo': _flatNoController.text,
        'floor': _floorController.text,
        'mobileNumber': _mobileNumberController.text,
        'secondaryMobileNumber': _secondaryMobileController.text,
        'email': _emailController.text,
        'nid': _nidController.text,
        'nocs': _nocsController.text,
        'feeder': _feederController.text,
        'billGroup': _billGroupController.text,
        'sanctionLoad': _sanctionLoadController.text,
        'bookNumber': _bookNumberController.text,
        'tariff': _tariffController.text,
        'fetchedOldMeterNumber': _fetchedOldMeterNumber, // Old meter number from customer data
        // Pass edit mode data if it exists
        if (widget.cmoData != null) ...{
          'id': widget.cmoData!['id'],
          'isEditMode': widget.cmoData!['isEditMode'],
          'oldMeterType': widget.cmoData!['oldMeterType'],
          'oldMeterCategory': widget.cmoData!['oldMeterCategory'],
          'oldMeterNumber': widget.cmoData!['oldMeterNumber'],
          'oldMeterImagePath': widget.cmoData!['oldMeterImagePath'],
          'oldMeterReading': widget.cmoData!['oldMeterReading'],
          'onPeak': widget.cmoData!['onPeak'],
          'offPeak': widget.cmoData!['offPeak'],
          'kvar': widget.cmoData!['kvar'],
          'newMeterImagePath': widget.cmoData!['newMeterImagePath'],
          'newMeterLatitude': widget.cmoData!['newMeterLatitude'],
          'newMeterLongitude': widget.cmoData!['newMeterLongitude'],
          'batteryCoverSeal': widget.cmoData!['batteryCoverSeal'],
          'batteryCoverSealImagePath': widget.cmoData!['batteryCoverSealImagePath'],
          'terminalSeal1': widget.cmoData!['terminalSeal1'],
          'terminalSeal2': widget.cmoData!['terminalSeal2'],
          'terminalCoverSealImagePath': widget.cmoData!['terminalCoverSealImagePath'],
          'hasSteelBox': widget.cmoData!['hasSteelBox'],
          'installBy': widget.cmoData!['installBy'],
        },
      };

      // Navigate to Old Meter Info screen
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OldMeterInfoScreen(cmoData: cmoData),
        ),
      );

      // Handle returned data from Old Meter Info screen
      if (result != null && result is Map<String, dynamic>) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CMO data collected successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
        // TODO: You can now save the complete CMO data including old meter info
        // final completeData = {...cmoData, ...result};
      }
    }
  }

  void _handleUpload() {
    // Check for duplicate customer
    if (_isDuplicateCustomer) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_duplicateMessage ?? 'Cannot upload. Customer already has meter installed!'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      // TODO: Implement upload logic
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CMO uploaded successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      });
    }
  }

  Future<void> _handleDraft() async {
    // Only require customer name and mobile number for draft
    if (_customerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter customer name to save as draft'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_mobileNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter mobile number to save as draft'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if in edit mode
      final isEditMode = widget.cmoData != null && widget.cmoData!['isEditMode'] == true;

      // Create CMO object with current data
      final cmo = CMO(
        id: isEditMode ? widget.cmoData!['id'] : null,
        customerId: _customerIdController.text.isNotEmpty ? _customerIdController.text : null,
        newMeterId: _newMeterController.text.isNotEmpty ? _newMeterController.text : null,
        customerName: _customerNameController.text,
        flatNo: _flatNoController.text.isNotEmpty ? _flatNoController.text : null,
        floor: _floorController.text.isNotEmpty ? _floorController.text : null,
        mobileNumber: _mobileNumberController.text,
        secondaryMobileNumber: _secondaryMobileController.text.isNotEmpty ? _secondaryMobileController.text : null,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        nid: _nidController.text.isNotEmpty ? _nidController.text : null,
        nocs: _nocsController.text.isNotEmpty ? _nocsController.text : null,
        feeder: _feederController.text.isNotEmpty ? _feederController.text : null,
        billGroup: _billGroupController.text.isNotEmpty ? _billGroupController.text : null,
        sanctionLoad: _sanctionLoadController.text.isNotEmpty ? _sanctionLoadController.text : null,
        bookNumber: _bookNumberController.text.isNotEmpty ? _bookNumberController.text : null,
        tariff: _tariffController.text.isNotEmpty ? _tariffController.text : null,
        // Preserve existing data if in edit mode
        oldMeterType: isEditMode ? widget.cmoData!['oldMeterType'] : null,
        oldMeterNumber: isEditMode ? widget.cmoData!['oldMeterNumber'] : null,
        oldMeterImagePath: isEditMode ? widget.cmoData!['oldMeterImagePath'] : null,
        oldMeterReading: isEditMode ? widget.cmoData!['oldMeterReading'] : null,
        onPeak: isEditMode ? widget.cmoData!['onPeak'] : null,
        offPeak: isEditMode ? widget.cmoData!['offPeak'] : null,
        kvar: isEditMode ? widget.cmoData!['kvar'] : null,
        batteryCoverSeal: isEditMode ? widget.cmoData!['batteryCoverSeal'] : null,
        batteryCoverSealImagePath: isEditMode ? widget.cmoData!['batteryCoverSealImagePath'] : null,
        terminalSeal1: isEditMode ? widget.cmoData!['terminalSeal1'] : null,
        terminalSeal2: isEditMode ? widget.cmoData!['terminalSeal2'] : null,
        terminalCoverSealImagePath: isEditMode ? widget.cmoData!['terminalCoverSealImagePath'] : null,
        hasSteelBox: isEditMode ? (widget.cmoData!['hasSteelBox'] ?? false) : false,
        installBy: isEditMode ? widget.cmoData!['installBy'] : null,
        status: 'draft',
      );

      bool success;
      if (isEditMode) {
        success = await DatabaseService.instance.updateCMO(cmo);
      } else {
        final id = await DatabaseService.instance.createCMO(cmo);
        success = id != null;
      }

      setState(() => _isLoading = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode ? 'Updated successfully!' : 'Saved as draft successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        // Navigate back to CMO list
        Navigator.of(context).pop();
      } else {
        throw Exception(isEditMode ? 'Failed to update' : 'Failed to save draft');
      }
    } catch (e) {
      setState(() => _isLoading = false);
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

  Future<void> _handleSearchCustomer() async {
    final customerId = _customerIdController.text.trim();

    if (customerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Customer ID'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _isDuplicateCustomer = false;
      _duplicateMessage = null;
    });

    try {
      // First check for local duplicate
      await _checkLocalCustomerDuplicate(customerId);

      final result = await CustomerApiService.instance.searchCustomerById(customerId);

      setState(() => _isSearching = false);

      if (result.success && result.customer != null) {
        // Check if customer already has meter installed (duplicate check)
        final isDuplicate = result.hasExistingInstallation;
        final meterInfo = result.meterInfoCheck;

        setState(() {
          _foundCustomer = result.customer;
          _isDuplicateCustomer = isDuplicate;

          if (isDuplicate && meterInfo != null) {
            _duplicateMessage = 'Customer already has meter installed!\n'
                'New Meter: ${meterInfo.newMeterNo ?? "N/A"}\n'
                'Install Date: ${meterInfo.installDate != null ? meterInfo.installDate!.toLocal().toString().split(' ')[0] : "N/A"}';
          }
        });

        // Populate form fields with customer data
        _populateCustomerData(result.customer!);

        if (mounted) {
          if (isDuplicate) {
            // Show error if duplicate
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_duplicateMessage ?? 'Customer already has meter installed!'),
                backgroundColor: AppTheme.errorColor,
                duration: const Duration(seconds: 5),
              ),
            );
          } else {
            // Show success if eligible
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${result.message} - Eligible for CMO (${result.source})'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching customer: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Store fetched old meter number from customer data
  String? _fetchedOldMeterNumber;

  void _populateCustomerData(Customer customer) {
    _customerNameController.text = customer.customerName ?? '';
    _flatNoController.text = customer.flatNo ?? '';
    _floorController.text = customer.floorNo ?? '';
    _mobileNumberController.text = customer.mobileNo ?? '';
    _secondaryMobileController.text = customer.secondaryMobileNo ?? '';
    _emailController.text = customer.emailId ?? '';
    _nidController.text = customer.nid ?? '';
    _nocsController.text = customer.nocs ?? '';
    _feederController.text = customer.feederName ?? '';
    _billGroupController.text = customer.billGroup ?? '';
    _sanctionLoadController.text = customer.sanctionedLoad ?? '';
    _bookNumberController.text = customer.book ?? '';
    _tariffController.text = customer.custTariffCategory ?? '';
    // Store old meter number for validation in Old Meter Info screen
    _fetchedOldMeterNumber = customer.oldMeterNo;
  }

  /// Check if meter ID is duplicate locally
  Future<void> _checkMeterDuplicate(String meterId) async {
    if (meterId.isEmpty) {
      setState(() {
        _isDuplicateMeter = false;
        _duplicateMeterMessage = null;
      });
      return;
    }

    // Get current CMO id for edit mode
    final excludeId = widget.cmoData?['id']?.toString();

    final isDuplicate = await DatabaseService.instance.isNewMeterIdDuplicate(
      meterId,
      excludeCmoId: excludeId,
    );

    if (isDuplicate) {
      final existingCmo = await DatabaseService.instance.getCMOByNewMeterId(meterId);
      setState(() {
        _isDuplicateMeter = true;
        _duplicateMeterMessage = 'Meter $meterId already exists!\n'
            'Customer: ${existingCmo?.customerName ?? "N/A"}\n'
            'Status: ${existingCmo?.status ?? "N/A"}';
      });

      if (mounted) {
        _showDuplicateDialog(
          'Duplicate Meter Number',
          _duplicateMeterMessage!,
          Icons.electric_meter,
          AppTheme.errorColor,
        );
      }
    } else {
      setState(() {
        _isDuplicateMeter = false;
        _duplicateMeterMessage = null;
      });
    }
  }

  /// Check if customer ID is duplicate locally
  Future<void> _checkLocalCustomerDuplicate(String customerId) async {
    if (customerId.isEmpty) return;

    // Get current CMO id for edit mode
    final excludeId = widget.cmoData?['id']?.toString();

    final isDuplicate = await DatabaseService.instance.isCustomerIdDuplicate(
      customerId,
      excludeCmoId: excludeId,
    );

    if (isDuplicate) {
      final existingCmo = await DatabaseService.instance.getCMOByCustomerId(customerId);
      final localDuplicateMsg = 'Customer $customerId already exists locally!\n'
          'Name: ${existingCmo?.customerName ?? "N/A"}\n'
          'Status: ${existingCmo?.status ?? "N/A"}';

      if (mounted) {
        _showDuplicateDialog(
          'Duplicate Customer ID (Local)',
          localDuplicateMsg,
          Icons.person,
          AppTheme.warningColor,
        );
      }
    }
  }

  /// Show duplicate warning dialog
  void _showDuplicateDialog(String title, String message, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(color: color))),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New CMO'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Form Section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Section
                      _buildSectionTitle('Search Information'),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _customerIdController,
                        label: 'Search Customer ID',
                        hint: 'Enter customer ID',
                        prefixIcon: Icons.person_search,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (value.length != 8 || !RegExp(r'^\d{8}$').hasMatch(value)) {
                              return 'Customer ID must be exactly 8 digits';
                            }
                          }
                          return null;
                        },
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                  ),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.search, color: AppTheme.primaryColor),
                                onPressed: _handleSearchCustomer,
                                tooltip: 'Search Customer',
                              ),
                      ),

                      if (_foundCustomer != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isDuplicateCustomer
                                ? AppTheme.errorColor.withOpacity(0.1)
                                : AppTheme.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isDuplicateCustomer
                                  ? AppTheme.errorColor
                                  : AppTheme.successColor,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _isDuplicateCustomer
                                        ? Icons.error_outline
                                        : Icons.check_circle,
                                    color: _isDuplicateCustomer
                                        ? AppTheme.errorColor
                                        : AppTheme.successColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _isDuplicateCustomer
                                          ? 'DUPLICATE - Meter Already Installed!'
                                          : 'Customer found: ${_foundCustomer!.customerName}',
                                      style: TextStyle(
                                        color: _isDuplicateCustomer
                                            ? AppTheme.errorColor
                                            : AppTheme.successColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_isDuplicateCustomer && _duplicateMessage != null) ...[
                                const SizedBox(height: 8),
                                const Divider(height: 1),
                                const SizedBox(height: 8),
                                Text(
                                  _duplicateMessage!,
                                  style: const TextStyle(
                                    color: AppTheme.errorColor,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.block, color: AppTheme.errorColor, size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Not eligible for CMO',
                                          style: const TextStyle(
                                            color: AppTheme.errorColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (!_isDuplicateCustomer) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.verified, color: AppTheme.successColor, size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Eligible for CMO',
                                          style: const TextStyle(
                                            color: AppTheme.successColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _newMeterController,
                        label: 'New Meter Number',
                        hint: 'Enter new meter number',
                        prefixIcon: Icons.electric_meter,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          // Optional field - only validate format if value is provided
                          if (value != null && value.isNotEmpty) {
                            if (value.length != 8 || !RegExp(r'^\d{8}$').hasMatch(value)) {
                              return 'Meter number must be exactly 8 digits';
                            }
                          }
                          return null;
                        },
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isDuplicateMeter)
                              const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Icon(Icons.warning, color: AppTheme.errorColor, size: 20),
                              ),
                            IconButton(
                              icon: const Icon(Icons.qr_code_scanner),
                              onPressed: () async {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const BarcodeScannerScreen(),
                                  ),
                                );
                                if (result != null && result is String) {
                                  setState(() {
                                    _newMeterController.text = result;
                                  });
                                  // Check for duplicate meter
                                  _checkMeterDuplicate(result);
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      // Show duplicate meter warning
                      if (_isDuplicateMeter && _duplicateMeterMessage != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _duplicateMeterMessage!,
                                  style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Customer Information Section
                      _buildSectionTitle('Customer Information'),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _customerNameController,
                        label: 'Customer Name *',
                        hint: 'Enter customer name',
                        prefixIcon: Icons.person,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Customer name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _flatNoController,
                              label: 'Flat No',
                              hint: 'Enter flat number',
                              prefixIcon: Icons.home_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _floorController,
                              label: 'Floor',
                              hint: 'Enter floor',
                              prefixIcon: Icons.stairs,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Contact Information Section
                      _buildSectionTitle('Contact Information'),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _mobileNumberController,
                        label: 'Mobile Number *',
                        hint: 'Enter mobile number',
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Mobile number is required';
                          }
                          if (value.length < 11) {
                            return 'Enter a valid mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _secondaryMobileController,
                        label: 'Secondary Mobile Number',
                        hint: 'Enter secondary mobile number',
                        prefixIcon: Icons.phone_android,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'Enter email address',
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 24),

                      // Additional Information Section
                      _buildSectionTitle('Additional Information'),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _nidController,
                        label: 'NID',
                        hint: 'Enter NID number',
                        prefixIcon: Icons.badge,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _nocsController,
                        label: 'NOCS',
                        hint: 'Enter NOCS',
                        prefixIcon: Icons.document_scanner,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _feederController,
                        label: 'Feeder',
                        hint: 'Enter feeder information',
                        prefixIcon: Icons.electrical_services,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _billGroupController,
                              label: 'Bill Group',
                              hint: 'Enter bill group',
                              prefixIcon: Icons.group,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _sanctionLoadController,
                              label: 'Sanction Load',
                              hint: 'Enter load',
                              prefixIcon: Icons.power,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _bookNumberController,
                              label: 'Book Number',
                              hint: 'Enter book number',
                              prefixIcon: Icons.book,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _tariffController,
                              label: 'Tariff',
                              hint: 'Enter tariff',
                              prefixIcon: Icons.attach_money,
                            ),
                          ),
                        ],
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

                        const SizedBox(width: 12),

                        // NEXT Button
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: AppTheme.primaryColor),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
