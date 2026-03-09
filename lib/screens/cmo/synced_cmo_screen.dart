import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../config/api_config.dart';
import '../../models/synced_cmo_model.dart';
import '../../services/api_client.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';

class SyncedCmoScreen extends StatefulWidget {
  const SyncedCmoScreen({super.key});

  @override
  State<SyncedCmoScreen> createState() => _SyncedCmoScreenState();
}

class _SyncedCmoScreenState extends State<SyncedCmoScreen> {
  final ApiClient _apiClient = ApiClient();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<SyncedCmoRecord> _records = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _totalRecords = 0;
  String? _error;

  // Quick filter
  String _quickFilter = 'all'; // all, approved, pending, revisit, mdm

  // Advanced filters
  String? _nocsFilter;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _installerFilter;
  String? _meterTypeFilter; // 1P, 3P
  int? _approvedFilter;
  int? _mdmFilter;
  int? _revisitFilter;

  // Dropdown options
  List<String> _nocsList = [];
  List<String> _installersList = [];
  bool _isLoadingOptions = false;

  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _loadFilterOptions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFilterOptions() async {
    if (_isLoadingOptions) return;
    setState(() => _isLoadingOptions = true);
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.cmsFilterOptions,
        requiresAuth: true,
        timeout: ApiConfig.listTimeout,
      );
      if (response.success && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>? ?? {};
        setState(() {
          _nocsList = List<String>.from(data['nocs'] ?? []);
          _installersList = List<String>.from(data['installers'] ?? []);
        });
      }
    } catch (_) {
      // silently fail — filters still work as text fallback
    } finally {
      if (mounted) setState(() => _isLoadingOptions = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Map<String, String> _buildQueryParams({int page = 1}) {
    final params = <String, String>{
      'page': '$page',
      'limit': '$_pageSize',
      'sortBy': 'CreateDate',
      'sortOrder': 'DESC',
    };

    final search = _searchController.text.trim();
    if (search.isNotEmpty) params['search'] = search;
    if (_nocsFilter != null && _nocsFilter!.isNotEmpty) params['nocs'] = _nocsFilter!;
    if (_installerFilter != null && _installerFilter!.isNotEmpty) params['installedBy'] = _installerFilter!;
    if (_meterTypeFilter != null) params['meterType'] = _meterTypeFilter!;
    if (_dateFrom != null) params['dateFrom'] = DateFormat('yyyy-MM-dd').format(_dateFrom!);
    if (_dateTo != null) params['dateTo'] = DateFormat('yyyy-MM-dd').format(_dateTo!);

    // Quick filter overrides approval/mdm/revisit
    switch (_quickFilter) {
      case 'approved':
        params['isApproved'] = '1';
        break;
      case 'pending':
        params['isApproved'] = '0';
        break;
      case 'revisit':
        params['hasRevisit'] = '1';
        break;
      case 'mdm':
        params['isMDMEntry'] = '1';
        break;
    }

    // Advanced overrides (when quick filter is 'all')
    if (_quickFilter == 'all') {
      if (_approvedFilter != null) params['isApproved'] = '$_approvedFilter';
      if (_mdmFilter != null) params['isMDMEntry'] = '$_mdmFilter';
      if (_revisitFilter != null) params['hasRevisit'] = '$_revisitFilter';
    }

    return params;
  }

  Future<void> _loadRecords({bool reset = false}) async {
    if (reset) {
      setState(() {
        _records = [];
        _currentPage = 1;
        _hasMore = true;
        _error = null;
        _isLoading = true;
      });
    } else {
      setState(() => _isLoading = true);
    }

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.cmsSyncedList,
        queryParameters: _buildQueryParams(page: 1),
        requiresAuth: true,
        timeout: ApiConfig.listTimeout,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        final data = response.data!;
        final List<dynamic> items = data['data'] ?? [];
        final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
        final total = pagination['total'] ?? 0;
        final totalPages = pagination['totalPages'] ?? 1;

        setState(() {
          _records = items.map((j) => SyncedCmoRecord.fromJson(j as Map<String, dynamic>)).toList();
          _currentPage = 1;
          _totalRecords = total;
          _hasMore = 1 < totalPages;
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = response.message.isNotEmpty ? response.message : 'Failed to load records';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.cmsSyncedList,
        queryParameters: _buildQueryParams(page: nextPage),
        requiresAuth: true,
        timeout: ApiConfig.listTimeout,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        final data = response.data!;
        final List<dynamic> items = data['data'] ?? [];
        final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
        final totalPages = pagination['totalPages'] ?? 1;

        setState(() {
          _records.addAll(items.map((j) => SyncedCmoRecord.fromJson(j as Map<String, dynamic>)));
          _currentPage = nextPage;
          _hasMore = nextPage < totalPages;
          _isLoadingMore = false;
        });
      } else {
        setState(() => _isLoadingMore = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _clearAllFilters() {
    _searchController.clear();
    setState(() {
      _quickFilter = 'all';
      _nocsFilter = null;
      _dateFrom = null;
      _dateTo = null;
      _installerFilter = null;
      _meterTypeFilter = null;
      _approvedFilter = null;
      _mdmFilter = null;
      _revisitFilter = null;
    });
    _loadRecords(reset: true);
  }

  bool get _hasActiveFilters =>
      _nocsFilter != null ||
      _dateFrom != null ||
      _dateTo != null ||
      _installerFilter != null ||
      _meterTypeFilter != null ||
      _approvedFilter != null ||
      _mdmFilter != null ||
      _revisitFilter != null;

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_dateFrom ?? DateTime.now()) : (_dateTo ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _dateFrom = picked;
        else _dateTo = picked;
      });
    }
  }

  void _showAdvancedFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtrl) => Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tune, color: AppTheme.primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Advanced Filters',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setSheetState(() {});
                        _clearAllFilters();
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: const Text('Clear All'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _filterSectionLabel('NOCS', Icons.electrical_services_outlined),
                    _isLoadingOptions
                        ? const Center(child: SizedBox(height: 36, width: 36, child: CircularProgressIndicator(strokeWidth: 2)))
                        : DropdownButtonFormField<String>(
                            value: _nocsFilter,
                            isExpanded: true,
                            decoration: _filterInputDecoration('Select NOCS'),
                            hint: const Text('All NOCS', style: TextStyle(fontSize: 13)),
                            items: [
                              const DropdownMenuItem<String>(value: null, child: Text('All NOCS', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                              ..._nocsList.map((n) => DropdownMenuItem<String>(
                                value: n,
                                child: Text(n, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                              )),
                            ],
                            onChanged: (v) => setSheetState(() => _nocsFilter = v),
                          ),
                    const SizedBox(height: 20),

                    _filterSectionLabel('Install Date Range', Icons.date_range_outlined),
                    Row(
                      children: [
                        Expanded(child: _datePickerButton(
                          label: _dateFrom != null ? DateFormat('dd MMM yyyy').format(_dateFrom!) : 'From Date',
                          icon: Icons.calendar_today_outlined,
                          hasValue: _dateFrom != null,
                          onTap: () async { await _pickDate(true); setSheetState(() {}); },
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _datePickerButton(
                          label: _dateTo != null ? DateFormat('dd MMM yyyy').format(_dateTo!) : 'To Date',
                          icon: Icons.calendar_today,
                          hasValue: _dateTo != null,
                          onTap: () async { await _pickDate(false); setSheetState(() {}); },
                        )),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _filterSectionLabel('Installer / User', Icons.person_outline),
                    _isLoadingOptions
                        ? const Center(child: SizedBox(height: 36, width: 36, child: CircularProgressIndicator(strokeWidth: 2)))
                        : DropdownButtonFormField<String>(
                            value: _installerFilter,
                            isExpanded: true,
                            decoration: _filterInputDecoration('Select Installer / User'),
                            hint: const Text('All Users', style: TextStyle(fontSize: 13)),
                            items: [
                              const DropdownMenuItem<String>(value: null, child: Text('All Users', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                              ..._installersList.map((u) => DropdownMenuItem<String>(
                                value: u,
                                child: Text(u, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                              )),
                            ],
                            onChanged: (v) => setSheetState(() => _installerFilter = v),
                          ),
                    const SizedBox(height: 20),

                    _filterSectionLabel('Meter Type', Icons.category_outlined),
                    _chipGroup(
                      options: const {'Any': null, '1-Phase (1P)': '1P', '3-Phase (3P)': '3P'},
                      selected: _meterTypeFilter,
                      onSelect: (v) => setSheetState(() => _meterTypeFilter = v),
                    ),
                    const SizedBox(height: 20),

                    _filterSectionLabel('Approval Status', Icons.verified_outlined),
                    _chipGroup(
                      options: const {'Any': null, 'Approved': 1, 'Pending': 0},
                      selected: _approvedFilter,
                      onSelect: (v) => setSheetState(() => _approvedFilter = v),
                    ),
                    const SizedBox(height: 20),

                    _filterSectionLabel('MDM Entry', Icons.check_circle_outline),
                    _chipGroup(
                      options: const {'Any': null, 'MDM Verified': 1, 'Not Verified': 0},
                      selected: _mdmFilter,
                      onSelect: (v) => setSheetState(() => _mdmFilter = v),
                    ),
                    const SizedBox(height: 20),

                    _filterSectionLabel('Revisit Status', Icons.redo_outlined),
                    _chipGroup(
                      options: const {'Any': null, 'Has Revisit': 1, 'No Revisit': 0},
                      selected: _revisitFilter,
                      onSelect: (v) => setSheetState(() => _revisitFilter = v),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {});
                      Navigator.pop(ctx);
                      _loadRecords(reset: true);
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterSectionLabel(String label, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.primaryColor),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
        )),
      ],
    ),
  );

  InputDecoration _filterInputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textHint),
    filled: true,
    fillColor: Colors.grey[100],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
  );

  Widget _datePickerButton({required String label, required IconData icon, required VoidCallback onTap, bool hasValue = false}) =>
    OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15, color: hasValue ? AppTheme.primaryColor : AppTheme.textSecondary),
      label: Text(label, style: TextStyle(fontSize: 12, color: hasValue ? AppTheme.primaryColor : AppTheme.textSecondary)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
        side: BorderSide(color: hasValue ? AppTheme.primaryColor : Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: hasValue ? AppTheme.primaryColor.withOpacity(0.05) : null,
      ),
    );

  Widget _chipGroup({
    required Map<String, dynamic> options,
    required dynamic selected,
    required void Function(dynamic) onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: options.entries.map((e) {
        final isSelected = selected == e.value;
        return GestureDetector(
          onTap: () => onSelect(e.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.transparent),
            ),
            child: Text(e.key,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildQuickFilters(),
            if (_hasActiveFilters) _buildActiveFiltersBanner(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Synced CMO Records',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isLoading ? 'Loading...' : '$_totalRecords records on server',
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              backgroundColor: Colors.orange,
              smallSize: 8,
              child: const Icon(Icons.tune, color: Colors.white),
            ),
            onPressed: _showAdvancedFilters,
            tooltip: 'Advanced Filters',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadRecords(reset: true),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search meter no, consumer ID, customer name...',
          hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textHint),
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () { _searchController.clear(); _loadRecords(reset: true); },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF4F6FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onSubmitted: (_) => _loadRecords(reset: true),
        textInputAction: TextInputAction.search,
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _quickFilterChip('All', 'all', Icons.grid_view_rounded, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            _quickFilterChip('Approved', 'approved', Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            _quickFilterChip('Pending', 'pending', Icons.hourglass_bottom, color: Colors.orange),
            const SizedBox(width: 8),
            _quickFilterChip('Revisit', 'revisit', Icons.redo, color: Colors.red),
            const SizedBox(width: 8),
            _quickFilterChip('MDM', 'mdm', Icons.verified, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _quickFilterChip(String label, String value, IconData icon, {required Color color}) {
    final isSelected = _quickFilter == value;
    return GestureDetector(
      onTap: () { setState(() => _quickFilter = value); _loadRecords(reset: true); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [color, color.withOpacity(0.7)])
              : null,
          color: isSelected ? null : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : color),
            const SizedBox(width: 5),
            Text(label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFiltersBanner() {
    final parts = <String>[];
    if (_nocsFilter != null) parts.add('NOCS: $_nocsFilter');
    if (_dateFrom != null) parts.add('From: ${DateFormat('dd MMM').format(_dateFrom!)}');
    if (_dateTo != null) parts.add('To: ${DateFormat('dd MMM').format(_dateTo!)}');
    if (_installerFilter != null) parts.add('User: $_installerFilter');
    if (_meterTypeFilter != null) parts.add('Type: $_meterTypeFilter');
    if (_approvedFilter != null) parts.add(_approvedFilter == 1 ? 'Approved' : 'Pending');
    if (_mdmFilter != null) parts.add(_mdmFilter == 1 ? 'MDM' : 'No MDM');
    if (_revisitFilter != null) parts.add(_revisitFilter == 1 ? 'Has Revisit' : 'No Revisit');

    return Container(
      color: AppTheme.primaryColor.withOpacity(0.07),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 15, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(parts.join('  •  '),
              style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: _clearAllFilters,
            child: const Text('Clear', style: TextStyle(fontSize: 12, color: AppTheme.errorColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text('Loading records...', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_off, size: 52, color: AppTheme.errorColor),
              ),
              const SizedBox(height: 20),
              const Text('Failed to load records', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _loadRecords(reset: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_done_outlined, size: 56, color: Colors.grey[300]),
            ),
            const SizedBox(height: 20),
            Text('No records found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[600])),
            const SizedBox(height: 6),
            Text('Try adjusting your search or filters',
              style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () => _loadRecords(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
        itemCount: _records.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _records.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor)),
            );
          }
          return _SyncedCmoCard(
            record: _records[index],
            index: index + 1,
            onRefresh: () => _loadRecords(reset: true),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card widget — redesigned
// ─────────────────────────────────────────────────────────────────────────────
class _SyncedCmoCard extends StatelessWidget {
  final SyncedCmoRecord record;
  final int index;
  final VoidCallback? onRefresh;
  const _SyncedCmoCard({required this.record, required this.index, this.onRefresh});

  Color get _statusColor => record.isApproved == 1 ? Colors.green : Colors.orange;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    String? displayDate;
    if (record.installDate != null) {
      try { displayDate = dateFormat.format(DateTime.parse(record.installDate!)); }
      catch (_) { displayDate = record.installDate; }
    }

    final initials = _getInitials(record.customerName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
        border: Border(
          left: BorderSide(color: _statusColor, width: 4),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetailSheet(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Row 1: Avatar + Name + Badges ──
                Row(
                  children: [
                    // Customer avatar
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_statusColor.withOpacity(0.8), _statusColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(initials,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Name + ID
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.customerName ?? 'Unknown Customer',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.tag, size: 11, color: AppTheme.textHint),
                              const SizedBox(width: 2),
                              Text(record.oldConsumerId ?? '—',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status + serial
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _StatusBadge(isApproved: record.isApproved),
                        const SizedBox(height: 4),
                        Text('#$index', style: const TextStyle(fontSize: 10, color: AppTheme.textHint)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey[100]),
                const SizedBox(height: 10),

                // ── Row 2: Meters ──
                Row(
                  children: [
                    Expanded(child: _MeterBox(
                      label: 'New Meter',
                      value: record.newMeterNoOCR,
                      icon: Icons.electric_meter,
                      color: AppTheme.primaryColor,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _MeterBox(
                      label: 'Old Meter',
                      value: record.oldMeterNoOCR,
                      icon: Icons.electric_meter_outlined,
                      color: Colors.grey[500]!,
                    )),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Row 3: Date, NOCS, Type ──
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _InfoPill(Icons.calendar_month_outlined, displayDate ?? '—', Colors.teal),
                    _InfoPill(Icons.electrical_services_outlined, record.customerNocs ?? '—', Colors.deepPurple),
                    if (record.newMeterType != null)
                      _InfoPill(Icons.category_outlined, record.newMeterType!, Colors.orange),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Row 4: Indicators ──
                Row(
                  children: [
                    _IndicatorChip(
                      label: record.hasGps ? 'GPS ✓' : 'No GPS',
                      color: record.hasGps ? Colors.green : Colors.grey,
                      icon: Icons.my_location,
                    ),
                    const SizedBox(width: 6),
                    _IndicatorChip(
                      label: '${record.imageCount} Photos',
                      color: record.imageCount > 0 ? Colors.indigo : Colors.grey,
                      icon: Icons.photo_library_outlined,
                    ),
                    if (record.hasSteelBox == 1) ...[
                      const SizedBox(width: 6),
                      _IndicatorChip(label: 'Steel Box', color: Colors.brown, icon: Icons.inventory_2_outlined),
                    ],
                    if (record.isMDMEntry == 1) ...[
                      const SizedBox(width: 6),
                      _IndicatorChip(label: 'MDM', color: Colors.blue, icon: Icons.verified),
                    ],
                    if (record.hasRevisit == 1) ...[
                      const SizedBox(width: 6),
                      _IndicatorChip(label: 'REVISIT', color: Colors.red, icon: Icons.redo),
                    ],
                    const Spacer(),
                    Icon(Icons.chevron_right, size: 18, color: Colors.grey[300]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  // ── Detail Bottom Sheet ────────────────────────────────────────────────────
  void _showDetailSheet(BuildContext context) {
    final apiClient = ApiClient();

    Future<void> toggleApproval(StateSetter setSheetState, bool approve) async {
      final newValue = approve ? 1 : 0;
      try {
        final response = await apiClient.patch<Map<String, dynamic>>(
          '${ApiConfig.cmsApprovalUpdate}/${record.id}/approval',
          body: {'isApproved': newValue},
        );
        if (!context.mounted) return;
        if (response.success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              Icon(approve ? Icons.check_circle : Icons.cancel, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(approve ? 'Record approved successfully' : 'Record returned to pending'),
            ]),
            backgroundColor: approve ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
          onRefresh?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(response.message),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }

    Future<void> requestReEdit() async {
      if (record.localId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Local record not linked. Please re-create this CMO manually.'),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.edit_note, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text('Re-edit CMO'),
          ]),
          content: const Text(
            'This will unlock the local CMO record so it can be edited and re-synced to the server.\n\nDo you want to continue?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
              child: const Text('Re-edit'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      final success = await DatabaseService.instance.unmarkCMOAsSynced(record.localId!);
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
          ? 'CMO unlocked. Go to CMO screen to edit and re-sync.'
          : 'Local record not found. Please re-create the CMO manually.'),
        backgroundColor: success ? Colors.orange : AppTheme.errorColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      onRefresh?.call();
    }

    void openPhoto(String url, String label) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _FullScreenImagePage(url: url, label: label),
      ));
    }

    final photoList = <MapEntry<String, String>>[
      if (record.oldMeterNoImgUrl != null)
        MapEntry('Old Meter No.', '${ApiConfig.baseUrl}${record.oldMeterNoImgUrl}'),
      if (record.oldMeterReadingImgUrl != null)
        MapEntry('Old Reading', '${ApiConfig.baseUrl}${record.oldMeterReadingImgUrl}'),
      if (record.newMeterNoImgUrl != null)
        MapEntry('New Meter No.', '${ApiConfig.baseUrl}${record.newMeterNoImgUrl}'),
      if (record.batteryCoverSealImgUrl != null)
        MapEntry('Battery Seal', '${ApiConfig.baseUrl}${record.batteryCoverSealImgUrl}'),
      if (record.terminalCoverSealImgUrl1 != null)
        MapEntry('Terminal Seal 1', '${ApiConfig.baseUrl}${record.terminalCoverSealImgUrl1}'),
      if (record.terminalCoverSealImgUrl2 != null)
        MapEntry('Terminal Seal 2', '${ApiConfig.baseUrl}${record.terminalCoverSealImgUrl2}'),
      if (record.steelBoxRemoveUrl != null)
        MapEntry('Steel Box', '${ApiConfig.baseUrl}${record.steelBoxRemoveUrl}'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.97,
          expand: false,
          builder: (_, ctrl) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF4F6FB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // ── Drag handle ──
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),

                // ── Gradient header ──
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: record.isApproved == 1
                          ? [const Color(0xFF00B09B), const Color(0xFF96C93D)]
                          : [const Color(0xFFf7971e), const Color(0xFFffd200)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: (record.isApproved == 1 ? Colors.green : Colors.orange).withOpacity(0.3),
                        blurRadius: 12, offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              record.customerName ?? 'Unknown Customer',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.5)),
                            ),
                            child: Text(
                              record.isApproved == 1 ? '✓ APPROVED' : '⏳ PENDING',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.tag, size: 13, color: Colors.white70),
                          const SizedBox(width: 3),
                          Text(record.oldConsumerId ?? '—',
                            style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 16),
                          if (record.customerNocs != null) ...[
                            const Icon(Icons.electrical_services_outlined, size: 13, color: Colors.white70),
                            const SizedBox(width: 3),
                            Text(record.customerNocs!,
                              style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Key info chips row
                      Wrap(
                        spacing: 6, runSpacing: 6,
                        children: [
                          if (record.installDate != null)
                            _HeaderChip(Icons.calendar_month, _formatDate(record.installDate)),
                          if (record.newMeterType != null)
                            _HeaderChip(Icons.category_outlined, record.newMeterType!),
                          if (record.hasGps)
                            const _HeaderChip(Icons.location_on, 'GPS ✓'),
                          if (record.isMDMEntry == 1)
                            const _HeaderChip(Icons.verified, 'MDM'),
                          if (record.hasRevisit == 1)
                            const _HeaderChip(Icons.redo, 'REVISIT'),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Scrollable content ──
                Expanded(
                  child: ListView(
                    controller: ctrl,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                    children: [

                      // ── Customer Info ──
                      _DetailCard(
                        title: 'Customer Information',
                        icon: Icons.person_outline,
                        iconColor: Colors.indigo,
                        children: [
                          _DetailRow(label: 'Full Name', value: record.customerName, icon: Icons.badge_outlined),
                          _DetailRow(label: 'Consumer ID', value: record.oldConsumerId, icon: Icons.tag, copyable: true),
                          _DetailRow(label: 'DB Customer ID', value: record.customerId, icon: Icons.fingerprint),
                          _DetailRow(label: 'Mobile', value: record.customerMobile, icon: Icons.phone_outlined, copyable: true),
                          _DetailRow(label: 'Address', value: record.customerAddress, icon: Icons.home_outlined),
                          _DetailRow(label: 'NOCS', value: record.customerNocs, icon: Icons.electrical_services_outlined),
                          _DetailRow(label: 'Feeder', value: record.customerFeeder, icon: Icons.cable_outlined),
                          _DetailRow(label: 'Zone', value: record.customerZone, icon: Icons.map_outlined),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Meter Comparison ──
                      _DetailCard(
                        title: 'Meter Information',
                        icon: Icons.electric_meter,
                        iconColor: AppTheme.primaryColor,
                        children: [
                          // New vs Old meter grid
                          Row(
                            children: [
                              Expanded(child: _MeterDetailBox(
                                title: 'New Meter',
                                meterNo: record.newMeterNoOCR,
                                type: record.newMeterType,
                                hasImage: record.hasNewMeterNo == 1 && record.newMeterNoImgUrl != null,
                                color: AppTheme.primaryColor,
                                isNew: true,
                              )),
                              const SizedBox(width: 10),
                              Expanded(child: _MeterDetailBox(
                                title: 'Old Meter',
                                meterNo: record.oldMeterNoOCR,
                                reading: record.oldMeterReadingOCR,
                                hasImage: record.hasOldMeterNo == 1 && record.oldMeterNoImgUrl != null,
                                color: Colors.grey[600]!,
                                isNew: false,
                              )),
                            ],
                          ),
                          // Old meter readings
                          if (record.oldMeterReadingOCR != null || record.oldMeterPeak != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Old Meter Readings',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(child: _ReadingBox('Total', record.oldMeterReadingOCR, Colors.blueGrey)),
                                      const SizedBox(width: 8),
                                      Expanded(child: _ReadingBox('Peak', record.oldMeterPeak, Colors.deepOrange)),
                                      const SizedBox(width: 8),
                                      Expanded(child: _ReadingBox('Off-Peak', record.oldMeterOffPeak, Colors.teal)),
                                      const SizedBox(width: 8),
                                      Expanded(child: _ReadingBox('KVAR', record.oldMeterKvar, Colors.purple)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Photos Gallery ──
                      if (photoList.isNotEmpty) ...[
                        _DetailCard(
                          title: 'Photos (${photoList.length})',
                          icon: Icons.photo_library_outlined,
                          iconColor: Colors.deepPurple,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 12,
                              children: photoList
                                  .map((e) => _PhotoTile(
                                        label: e.key,
                                        imageUrl: e.value,
                                        onTap: () => openPhoto(e.value, e.key),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── Seal Info ──
                      _DetailCard(
                        title: 'Seal Information',
                        icon: Icons.lock_outline,
                        iconColor: Colors.teal,
                        children: [
                          _SealRow(
                            label: 'Battery Cover Seal',
                            sealNo: record.batteryCoverSealOCR,
                            hasImage: record.hasBatteryCoverSeal == 1,
                            hasImageUrl: record.batteryCoverSealImgUrl != null,
                          ),
                          const SizedBox(height: 8),
                          _SealRow(
                            label: 'Terminal Seal 1',
                            sealNo: record.terminalCoverSealOCR1,
                            hasImage: record.hasTerminalCoverSeal1 == 1,
                            hasImageUrl: record.terminalCoverSealImgUrl1 != null,
                          ),
                          const SizedBox(height: 8),
                          _SealRow(
                            label: 'Terminal Seal 2',
                            sealNo: record.terminalCoverSealOCR2,
                            hasImage: record.hasTerminalCoverSeal2 == 1,
                            hasImageUrl: record.terminalCoverSealImgUrl2 != null,
                          ),
                          const SizedBox(height: 8),
                          _DetailRow(
                            label: 'Steel Box',
                            value: record.hasSteelBox == 1 ? 'Installed' : 'Not Installed',
                            icon: Icons.inventory_2_outlined,
                            valueColor: record.hasSteelBox == 1 ? Colors.brown : Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Installation & GPS ──
                      _DetailCard(
                        title: 'Installation & Location',
                        icon: Icons.location_on_outlined,
                        iconColor: Colors.green,
                        children: [
                          _DetailRow(label: 'Install Date', value: _formatDate(record.installDate), icon: Icons.calendar_month_outlined),
                          _DetailRow(label: 'Installed By', value: record.installerName ?? record.meterInstalledBy, icon: Icons.engineering_outlined),
                          if (record.hasGps) ...[
                            _DetailRow(label: 'Latitude', value: record.latitude?.toStringAsFixed(7), icon: Icons.explore_outlined, copyable: true),
                            _DetailRow(label: 'Longitude', value: record.longitude?.toStringAsFixed(7), icon: Icons.explore_outlined, copyable: true),
                          ] else
                            _DetailRow(label: 'GPS', value: 'Not captured', icon: Icons.location_off_outlined, valueColor: Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Status & Audit ──
                      _DetailCard(
                        title: 'Status & Audit',
                        icon: Icons.info_outline,
                        iconColor: Colors.blueGrey,
                        children: [
                          _DetailRowBool('Approved', record.isApproved == 1, Colors.green),
                          _DetailRowBool('MDM Entry', record.isMDMEntry == 1, Colors.blue),
                          _DetailRowBool('From App', record.isAppsEntry == 1, AppTheme.primaryColor),
                          _DetailRowBool('Has Revisit', record.hasRevisit == 1, Colors.red),
                          if (record.rectifyStatus != null)
                            _DetailRow(label: 'Rectify Status', value: record.rectifyStatus, icon: Icons.build_outlined),
                          const Divider(height: 16),
                          _DetailRow(label: 'Record ID', value: '${record.id}', icon: Icons.numbers, copyable: true),
                          _DetailRow(label: 'Local ID', value: record.localId != null ? '${record.localId}' : 'N/A', icon: Icons.storage_outlined),
                          _DetailRow(label: 'Created', value: _formatDateTime(record.createDate), icon: Icons.schedule),
                          _DetailRow(label: 'Updated', value: _formatDateTime(record.updateDate), icon: Icons.update),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Admin Actions ──
                      if (record.isApproved == 1)
                        _ActionButton(
                          label: 'Unapprove — Return to Pending',
                          icon: Icons.cancel_outlined,
                          color: Colors.orange,
                          outlined: true,
                          onTap: () => toggleApproval(setSheetState, false),
                        )
                      else ...[
                        _ActionButton(
                          label: 'Approve Record',
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                          onTap: () => toggleApproval(setSheetState, true),
                        ),
                        const SizedBox(height: 10),
                        _ActionButton(
                          label: 'Re-edit & Re-sync',
                          icon: Icons.edit_note,
                          color: Colors.deepOrange,
                          outlined: true,
                          onTap: requestReEdit,
                        ),
                      ],
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return '—';
    try { return DateFormat('dd MMM yyyy').format(DateTime.parse(raw)); }
    catch (_) { return raw; }
  }

  String _formatDateTime(String? raw) {
    if (raw == null) return '—';
    try { return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(raw)); }
    catch (_) { return raw; }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable detail sheet widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;
  const _DetailCard({required this.title, required this.icon, required this.iconColor, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[100]),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final bool copyable;
  final Color? valueColor;
  const _DetailRow({required this.label, required this.value, required this.icon,
    this.copyable = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? value! : '—',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: valueColor ?? (hasValue ? AppTheme.textPrimary : AppTheme.textHint),
                    ),
                  ),
                ),
                if (copyable && hasValue)
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Copied: $value'), duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating),
                      );
                    },
                    child: Icon(Icons.copy, size: 14, color: Colors.grey[400]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRowBool extends StatelessWidget {
  final String label;
  final bool value;
  final Color activeColor;
  const _DetailRowBool(this.label, this.value, this.activeColor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(value ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: value ? activeColor : Colors.grey[300],
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ),
          Text(
            value ? 'Yes' : 'No',
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: value ? activeColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _MeterDetailBox extends StatelessWidget {
  final String title;
  final String? meterNo;
  final String? type;
  final String? reading;
  final bool hasImage;
  final Color color;
  final bool isNew;
  const _MeterDetailBox({
    required this.title, this.meterNo, this.type, this.reading,
    required this.hasImage, required this.color, required this.isNew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isNew ? Icons.electric_meter : Icons.electric_meter_outlined, size: 14, color: color),
              const SizedBox(width: 4),
              Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            meterNo ?? '—',
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold,
              color: meterNo != null ? AppTheme.textPrimary : AppTheme.textHint,
            ),
          ),
          if (type != null) ...[
            const SizedBox(height: 4),
            Text(type!, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
          if (reading != null) ...[
            const SizedBox(height: 4),
            Text('Reading: $reading', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(hasImage ? Icons.photo_camera : Icons.no_photography_outlined,
                size: 12,
                color: hasImage ? Colors.green : Colors.grey[400],
              ),
              const SizedBox(width: 3),
              Text(hasImage ? 'Image ✓' : 'No Image',
                style: TextStyle(fontSize: 10, color: hasImage ? Colors.green : Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SealRow extends StatelessWidget {
  final String label;
  final String? sealNo;
  final bool hasImage;
  final bool hasImageUrl;
  const _SealRow({required this.label, this.sealNo, required this.hasImage, required this.hasImageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 15, color: Colors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                Text(
                  sealNo ?? '—',
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: sealNo != null ? AppTheme.textPrimary : AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ),
          if (hasImage)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.image, size: 12, color: Colors.green),
                  const SizedBox(width: 3),
                  Text(hasImageUrl ? 'Image ✓' : 'No URL',
                    style: TextStyle(fontSize: 10, color: hasImageUrl ? Colors.green : Colors.orange)),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('No Image', style: TextStyle(fontSize: 10, color: AppTheme.textHint)),
            ),
        ],
      ),
    );
  }
}

class _ReadingBox extends StatelessWidget {
  final String label;
  final String? value;
  final Color color;
  const _ReadingBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            value ?? '—',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: value != null ? color : Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;
  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.22),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: Colors.white),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Card-level small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _MeterBox extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final Color color;
  const _MeterBox({required this.label, this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
              Text(
                value ?? '—',
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold,
                  color: value != null ? AppTheme.textPrimary : AppTheme.textHint,
                ),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoPill(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final int isApproved;
  const _StatusBadge({required this.isApproved});

  @override
  Widget build(BuildContext context) {
    final approved = isApproved == 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (approved ? Colors.green : Colors.orange).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (approved ? Colors.green : Colors.orange).withOpacity(0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(approved ? Icons.check_circle : Icons.hourglass_bottom,
            size: 10, color: approved ? Colors.green : Colors.orange),
          const SizedBox(width: 3),
          Text(
            approved ? 'APPROVED' : 'PENDING',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
              color: approved ? Colors.green : Colors.orange),
          ),
        ],
      ),
    );
  }
}

class _IndicatorChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _IndicatorChip({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Photo Gallery Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoTile extends StatelessWidget {
  final String label;
  final String imageUrl;
  final VoidCallback onTap;
  const _PhotoTile({required this.label, required this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
              loadingBuilder: (ctx, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: 88,
                  height: 88,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              },
              errorBuilder: (ctx, err, st) => Container(
                width: 88,
                height: 88,
                color: Colors.grey[100],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 28),
                    const SizedBox(height: 4),
                    Text('Error', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenImagePage extends StatelessWidget {
  final String url;
  final String label;
  const _FullScreenImagePage({required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(label, style: const TextStyle(fontSize: 16)),
        elevation: 0,
      ),
      body: InteractiveViewer(
        panEnabled: true,
        minScale: 0.5,
        maxScale: 6.0,
        child: Center(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (ctx, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorBuilder: (ctx, err, st) => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image, color: Colors.white54, size: 72),
                  SizedBox(height: 12),
                  Text('Image not available', style: TextStyle(color: Colors.white54, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
