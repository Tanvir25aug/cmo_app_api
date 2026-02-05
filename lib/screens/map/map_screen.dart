import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/map_api_service.dart';
import '../../utils/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  // CMO Data (from SQL Server API)
  List<Map<String, dynamic>> _allCMOs = [];
  List<Map<String, dynamic>> _filteredCMOs = [];

  // NOCS & DCU Data
  List<Map<String, dynamic>> _nocsList = [];
  List<Map<String, dynamic>> _dcuList = [];
  List<Map<String, dynamic>> _filteredDCUs = [];

  bool _isLoading = true;
  bool _isLoadingMapData = false;
  Position? _currentPosition;

  // Selected items
  Map<String, dynamic>? _selectedCMO;
  Map<String, dynamic>? _selectedNOCS;
  Map<String, dynamic>? _selectedDCU;

  // Filter states - CMO status (from SQL Server)
  bool _showPending = true;
  bool _showApproved = true;
  bool _showRevisit = true;

  // Filter states - Layer visibility
  bool _showCMOs = true;
  bool _showNOCS = true;
  bool _showDCUs = true;

  // NOCS filter
  String? _selectedNOCSFilter;

  // Default center (Bangladesh - Dhaka)
  final LatLng _defaultCenter = const LatLng(23.8103, 90.4125);

  @override
  void initState() {
    super.initState();
    _loadData();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load all data from API (NOCS, DCUs, and CMOs from SQL Server)
      await _loadMapDataFromAPI();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _applyFilters();

        // Fit bounds to show all markers
        if (_filteredCMOs.isNotEmpty || _nocsList.isNotEmpty || _dcuList.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 500), _fitBounds);
        }
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadMapDataFromAPI() async {
    setState(() => _isLoadingMapData = true);
    try {
      // Load NOCS and DCUs
      final mapData = await MapApiService.instance.getAllMapData();

      // Load CMOs from SQL Server
      final cmos = await MapApiService.instance.getCMOsWithCoordinates();

      if (mounted) {
        setState(() {
          _nocsList = List<Map<String, dynamic>>.from(mapData['nocs'] ?? []);
          _dcuList = List<Map<String, dynamic>>.from(mapData['dcus'] ?? []);
          _filteredDCUs = _dcuList;
          _allCMOs = cmos;
          _filteredCMOs = cmos;
          _isLoadingMapData = false;
        });
      }
    } catch (e) {
      print('Error loading map data: $e');
      if (mounted) {
        setState(() => _isLoadingMapData = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (mounted) {
        setState(() => _currentPosition = position);
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      // Filter CMOs from SQL Server
      _filteredCMOs = _allCMOs.where((cmo) {
        // Status filter
        final status = (cmo['status'] ?? '').toString().toLowerCase();
        if (status == 'pending' && !_showPending) return false;
        if (status == 'approved' && !_showApproved) return false;
        if (status == 'revisit' && !_showRevisit) return false;

        // Search filter
        final query = _searchController.text.toLowerCase();
        if (query.isNotEmpty) {
          final meterNumber = (cmo['oldMeterNumber'] ?? '').toString().toLowerCase();
          final customerId = (cmo['customerId'] ?? '').toString().toLowerCase();
          final newMeterNumber = (cmo['newMeterNumber'] ?? '').toString().toLowerCase();
          final oldConsumerId = (cmo['oldConsumerId'] ?? '').toString().toLowerCase();

          if (!meterNumber.contains(query) &&
              !customerId.contains(query) &&
              !newMeterNumber.contains(query) &&
              !oldConsumerId.contains(query)) {
            return false;
          }
        }

        return true;
      }).toList();

      // Filter DCUs by NOCS
      if (_selectedNOCSFilter != null && _selectedNOCSFilter!.isNotEmpty) {
        _filteredDCUs = _dcuList.where((dcu) {
          return dcu['nocs'] == _selectedNOCSFilter;
        }).toList();
      } else {
        _filteredDCUs = _dcuList;
      }

      // Clear selections
      _selectedCMO = null;
      _selectedNOCS = null;
      _selectedDCU = null;
    });
  }

  void _fitBounds() {
    List<LatLng> points = [];

    // Add CMO points (from SQL Server)
    if (_showCMOs) {
      points.addAll(_filteredCMOs
          .where((cmo) => cmo['latitude'] != null && cmo['longitude'] != null)
          .map((cmo) => LatLng(cmo['latitude'], cmo['longitude'])));
    }

    // Add NOCS points
    if (_showNOCS) {
      points.addAll(_nocsList
          .where((nocs) => nocs['latitude'] != null && nocs['longitude'] != null)
          .map((nocs) => LatLng(nocs['latitude'], nocs['longitude'])));
    }

    // Add DCU points
    if (_showDCUs) {
      points.addAll(_filteredDCUs
          .where((dcu) => dcu['latitude'] != null && dcu['longitude'] != null)
          .map((dcu) => LatLng(dcu['latitude'], dcu['longitude'])));
    }

    if (points.isEmpty) return;

    if (points.length == 1) {
      _mapController.move(points.first, 15);
      return;
    }

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  Color _getCMOMarkerColor(Map<String, dynamic> cmo) {
    final status = (cmo['status'] ?? '').toString().toLowerCase();
    switch (status) {
      case 'approved':
        return AppTheme.successColor;
      case 'revisit':
        return Colors.orange;
      case 'pending':
      default:
        return AppTheme.warningColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meter Map View'),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: _showLayerDialog,
            tooltip: 'Layers',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search meter/customer...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _applyFilters();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (_) => _applyFilters(),
                  ),
                ),
                const SizedBox(width: 8),
                // NOCS Filter Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedNOCSFilter,
                      hint: const Text('NOCS'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All NOCS'),
                        ),
                        ..._nocsList.map((nocs) => DropdownMenuItem<String>(
                          value: nocs['name']?.toString(),
                          child: Text(
                            nocs['name']?.toString() ?? 'Unknown',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedNOCSFilter = value;
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Statistics Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Theme.of(context).cardColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_showCMOs)
                    _buildStatChip(Icons.electric_meter, '${_filteredCMOs.length}', 'CMOs', AppTheme.primaryColor),
                  if (_showCMOs) const SizedBox(width: 8),
                  if (_showNOCS)
                    _buildStatChip(Icons.business, '${_nocsList.length}', 'NOCS', Colors.purple),
                  if (_showNOCS) const SizedBox(width: 8),
                  if (_showDCUs)
                    _buildStatChip(Icons.router, '${_filteredDCUs.length}', 'DCUs', Colors.teal),
                ],
              ),
            ),
          ),

          // Map
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _currentPosition != null
                              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                              : _defaultCenter,
                          initialZoom: 12,
                          onTap: (_, __) {
                            setState(() {
                              _selectedCMO = null;
                              _selectedNOCS = null;
                              _selectedDCU = null;
                            });
                          },
                        ),
                        children: [
                          // OpenStreetMap Tile Layer
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.otbl.cmo_app',
                          ),

                          // NOCS Markers (Substations) - Show first (bottom layer)
                          if (_showNOCS)
                            MarkerLayer(
                              markers: _buildNOCSMarkers(),
                            ),

                          // DCU Markers
                          if (_showDCUs)
                            MarkerLayer(
                              markers: _buildDCUMarkers(),
                            ),

                          // CMO Markers (top layer)
                          if (_showCMOs)
                            MarkerLayer(
                              markers: _buildCMOMarkers(),
                            ),

                          // Current location marker
                          if (_currentPosition != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                  width: 40,
                                  height: 40,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.3),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.blue, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.my_location,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),

                      // Loading overlay for map data
                      if (_isLoadingMapData)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Loading...', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),

                      // Selected CMO Info Card
                      if (_selectedCMO != null)
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: _buildCMOInfoCard(_selectedCMO!),
                        ),

                      // Selected NOCS Info Card
                      if (_selectedNOCS != null)
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: _buildNOCSInfoCard(_selectedNOCS!),
                        ),

                      // Selected DCU Info Card
                      if (_selectedDCU != null)
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: _buildDCUInfoCard(_selectedDCU!),
                        ),

                      // Map Controls
                      Positioned(
                        right: 16,
                        bottom: (_selectedCMO != null || _selectedNOCS != null || _selectedDCU != null) ? 200 : 16,
                        child: Column(
                          children: [
                            FloatingActionButton.small(
                              heroTag: 'zoom_in',
                              onPressed: () {
                                final currentZoom = _mapController.camera.zoom;
                                _mapController.move(_mapController.camera.center, currentZoom + 1);
                              },
                              child: const Icon(Icons.add),
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton.small(
                              heroTag: 'zoom_out',
                              onPressed: () {
                                final currentZoom = _mapController.camera.zoom;
                                _mapController.move(_mapController.camera.center, currentZoom - 1);
                              },
                              child: const Icon(Icons.remove),
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton.small(
                              heroTag: 'fit_bounds',
                              onPressed: _fitBounds,
                              tooltip: 'Fit all markers',
                              child: const Icon(Icons.fit_screen),
                            ),
                            const SizedBox(height: 8),
                            if (_currentPosition != null)
                              FloatingActionButton.small(
                                heroTag: 'my_location',
                                onPressed: () {
                                  _mapController.move(
                                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                    15,
                                  );
                                },
                                tooltip: 'My location',
                                child: const Icon(Icons.my_location),
                              ),
                          ],
                        ),
                      ),

                      // Legend
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: _buildLegend(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildCMOMarkers() {
    return _filteredCMOs
        .where((cmo) => cmo['latitude'] != null && cmo['longitude'] != null)
        .map((cmo) {
      final isSelected = _selectedCMO?['id'] == cmo['id'];
      final color = _getCMOMarkerColor(cmo);

      return Marker(
        point: LatLng(cmo['latitude'], cmo['longitude']),
        width: isSelected ? 45 : 35,
        height: isSelected ? 45 : 35,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedCMO = cmo;
              _selectedNOCS = null;
              _selectedDCU = null;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: isSelected ? 8 : 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.electric_meter,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Marker> _buildNOCSMarkers() {
    return _nocsList
        .where((nocs) => nocs['latitude'] != null && nocs['longitude'] != null)
        .map((nocs) {
      final isSelected = _selectedNOCS?['id'] == nocs['id'];

      return Marker(
        point: LatLng(nocs['latitude'], nocs['longitude']),
        width: isSelected ? 55 : 45,
        height: isSelected ? 55 : 45,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedNOCS = nocs;
              _selectedCMO = null;
              _selectedDCU = null;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.purple,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.4),
                  blurRadius: isSelected ? 12 : 6,
                  spreadRadius: isSelected ? 2 : 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.business,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Marker> _buildDCUMarkers() {
    return _filteredDCUs
        .where((dcu) => dcu['latitude'] != null && dcu['longitude'] != null)
        .map((dcu) {
      final isSelected = _selectedDCU?['id'] == dcu['id'];

      return Marker(
        point: LatLng(dcu['latitude'], dcu['longitude']),
        width: isSelected ? 45 : 35,
        height: isSelected ? 45 : 35,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedDCU = dcu;
              _selectedCMO = null;
              _selectedNOCS = null;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withValues(alpha: 0.4),
                  blurRadius: isSelected ? 8 : 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.router,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildStatChip(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Legend', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          if (_showNOCS) _buildLegendItem(Icons.business, 'NOCS', Colors.purple),
          if (_showDCUs) _buildLegendItem(Icons.router, 'DCU', Colors.teal),
          if (_showCMOs) _buildLegendItem(Icons.electric_meter, 'Meter', AppTheme.primaryColor),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 9, color: color)),
        ],
      ),
    );
  }

  Widget _buildCMOInfoCard(Map<String, dynamic> cmo) {
    final color = _getCMOMarkerColor(cmo);
    final status = (cmo['status'] ?? 'pending').toString();

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.electric_meter, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cmo['customerId']?.toString() ?? 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedCMO = null)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildInfoItem(Icons.speed, 'Old Meter', cmo['oldMeterNumber']?.toString() ?? 'N/A')),
                Expanded(child: _buildInfoItem(Icons.fiber_new, 'New Meter', cmo['newMeterNumber']?.toString() ?? 'N/A')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildInfoItem(Icons.category, 'Type', cmo['newMeterType']?.toString() ?? 'N/A')),
                Expanded(child: _buildInfoItem(Icons.person, 'Installed By', cmo['installedBy']?.toString() ?? 'N/A')),
              ],
            ),
            if (cmo['hasRevisit'] == true && cmo['rectifyMessage'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cmo['rectifyMessage']?.toString() ?? '',
                        style: const TextStyle(fontSize: 11, color: Colors.orange),
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
    );
  }

  Widget _buildNOCSInfoCard(Map<String, dynamic> nocs) {
    final dcuCount = _dcuList.where((dcu) => dcu['nocs'] == nocs['name']).length;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.business, color: Colors.purple, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('NOCS (Substation)', style: TextStyle(fontSize: 11, color: Colors.purple)),
                      Text(nocs['name']?.toString() ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedNOCS = null)),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(Icons.router, 'DCUs Under', '$dcuCount'),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.location_on,
                    'Coordinates',
                    '${nocs['latitude']?.toStringAsFixed(4)}, ${nocs['longitude']?.toStringAsFixed(4)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedNOCSFilter = nocs['name'];
                    _selectedNOCS = null;
                  });
                  _applyFilters();
                },
                icon: const Icon(Icons.filter_alt),
                label: Text('Show $dcuCount DCUs'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDCUInfoCard(Map<String, dynamic> dcu) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.router, color: Colors.teal, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DCU (Data Concentrator)', style: TextStyle(fontSize: 11, color: Colors.teal)),
                      Text(dcu['dcuId']?.toString() ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedDCU = null)),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildInfoItem(Icons.location_city, 'Address', dcu['address']?.toString() ?? 'N/A'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildInfoItem(Icons.business, 'NOCS', dcu['nocs']?.toString() ?? 'N/A')),
                Expanded(
                  child: _buildInfoItem(
                    Icons.location_on,
                    'Coordinates',
                    '${dcu['latitude']?.toStringAsFixed(4)}, ${dcu['longitude']?.toStringAsFixed(4)}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  void _showLayerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Map Layers', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('NOCS (Substations)'),
                    subtitle: Text('${_nocsList.length} substations'),
                    secondary: const Icon(Icons.business, color: Colors.purple),
                    value: _showNOCS,
                    onChanged: (value) {
                      setModalState(() => _showNOCS = value);
                      setState(() => _showNOCS = value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('DCUs'),
                    subtitle: Text('${_filteredDCUs.length} data concentrators'),
                    secondary: const Icon(Icons.router, color: Colors.teal),
                    value: _showDCUs,
                    onChanged: (value) {
                      setModalState(() => _showDCUs = value);
                      setState(() => _showDCUs = value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('CMO Meters'),
                    subtitle: Text('${_filteredCMOs.length} meters'),
                    secondary: Icon(Icons.electric_meter, color: AppTheme.primaryColor),
                    value: _showCMOs,
                    onChanged: (value) {
                      setModalState(() => _showCMOs = value);
                      setState(() => _showCMOs = value);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filter CMO Status', style: Theme.of(context).textTheme.titleLarge),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _showPending = true;
                            _showApproved = true;
                            _showRevisit = true;
                          });
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Pending'),
                        selected: _showPending,
                        onSelected: (value) => setModalState(() => _showPending = value),
                        selectedColor: AppTheme.warningColor,
                      ),
                      FilterChip(
                        label: const Text('Approved'),
                        selected: _showApproved,
                        onSelected: (value) => setModalState(() => _showApproved = value),
                        selectedColor: AppTheme.successColor,
                      ),
                      FilterChip(
                        label: const Text('Revisit'),
                        selected: _showRevisit,
                        onSelected: (value) => setModalState(() => _showRevisit = value),
                        selectedColor: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _applyFilters();
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
