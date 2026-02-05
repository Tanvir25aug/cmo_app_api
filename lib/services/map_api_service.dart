import 'api_client.dart';

class MapApiService {
  static final MapApiService _instance = MapApiService._internal();
  static MapApiService get instance => _instance;

  final ApiClient _apiClient = ApiClient();

  MapApiService._internal();

  // Get all NOCS (substations)
  Future<List<Map<String, dynamic>>> getAllNOCS() async {
    try {
      final response = await _apiClient.get(
        '/map/nocs',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data as List);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      print('Get NOCS error: $e');
      rethrow;
    }
  }

  // Get all DCUs
  Future<List<Map<String, dynamic>>> getAllDCUs({String? nocs}) async {
    try {
      String endpoint = '/map/dcus';
      if (nocs != null && nocs.isNotEmpty) {
        endpoint += '?nocs=$nocs';
      }

      final response = await _apiClient.get(
        endpoint,
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data as List);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      print('Get DCUs error: $e');
      rethrow;
    }
  }

  // Get all map data (NOCS + DCUs)
  Future<Map<String, dynamic>> getAllMapData({String? nocs}) async {
    try {
      String endpoint = '/map';
      if (nocs != null && nocs.isNotEmpty) {
        endpoint += '?nocs=$nocs';
      }

      final response = await _apiClient.get(
        endpoint,
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      print('Get map data error: $e');
      rethrow;
    }
  }

  // Get NOCS by ID with its DCUs
  Future<Map<String, dynamic>> getNOCSById(int id) async {
    try {
      final response = await _apiClient.get(
        '/map/nocs/$id',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      print('Get NOCS by ID error: $e');
      rethrow;
    }
  }

  // Get DCU by ID
  Future<Map<String, dynamic>> getDCUById(int id) async {
    try {
      final response = await _apiClient.get(
        '/map/dcus/$id',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      print('Get DCU by ID error: $e');
      rethrow;
    }
  }

  // Get all CMOs with coordinates from SQL Server
  Future<List<Map<String, dynamic>>> getCMOsWithCoordinates({String? search, String? status}) async {
    try {
      String endpoint = '/map/cmos';
      List<String> params = [];

      if (search != null && search.isNotEmpty) {
        params.add('search=$search');
      }
      if (status != null && status.isNotEmpty) {
        params.add('status=$status');
      }

      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }

      final response = await _apiClient.get(
        endpoint,
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data as List);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      print('Get CMOs with coordinates error: $e');
      rethrow;
    }
  }

  // Get CMO by ID from SQL Server
  Future<Map<String, dynamic>> getCMOById(int id) async {
    try {
      final response = await _apiClient.get(
        '/map/cmos/$id',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      print('Get CMO by ID error: $e');
      rethrow;
    }
  }
}
