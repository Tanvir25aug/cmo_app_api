import '../models/customer_model.dart';
import '../models/meter_info_check_model.dart';
import 'api_client.dart';
import 'database_service.dart';

class CustomerApiService {
  static final CustomerApiService instance = CustomerApiService._internal();
  factory CustomerApiService() => instance;
  CustomerApiService._internal();

  final _apiClient = ApiClient();
  final _dbService = DatabaseService.instance;

  // Check if customer already has meter installed (exists in MeterInfo table)
  // This prevents duplicate CMO entries
  Future<MeterInfoCheckResult> checkMeterInfoDuplicate(String customerId) async {
    try {
      print('🔍 Checking if customer already has meter installed: $customerId');

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/customer/$customerId/meter-info-check',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final result = MeterInfoCheckResult.fromJson(response.data!);

        if (result.isDuplicate) {
          print('⚠️ Customer already has meter installed!');
        } else {
          print('✅ Customer is eligible for new CMO');
        }

        return result;
      } else {
        // If API fails, assume customer is eligible (offline mode)
        print('⚠️ Could not verify meter info online, allowing CMO creation');
        return MeterInfoCheckResult(
          exists: false,
          isDuplicate: false,
          message: 'Could not verify online. Proceeding with caution.',
        );
      }
    } catch (e) {
      print('❌ Error checking meter info: $e');
      // In case of error, allow CMO creation (fail-safe)
      return MeterInfoCheckResult(
        exists: false,
        isDuplicate: false,
        message: 'Could not verify: $e',
      );
    }
  }

  // Search customer by OLD_CONSUMER_ID (tries local DB first, then API if not found)
  // Also checks for duplicate in MeterInfo table
  Future<CustomerSearchResult> searchCustomerById(String oldConsumerId) async {
    try {
      // STEP 1: Try to find in local database first (last 5000 customers)
      print('🔍 Searching customer in local database first: $oldConsumerId');
      final localCustomer = await _dbService.getCustomerByOldConsumerId(oldConsumerId);

      if (localCustomer != null) {
        print('✅ Customer found in local database (offline)');

        // STEP 1.5: Check if customer already has meter installed
        final meterInfoCheck = await checkMeterInfoDuplicate(oldConsumerId);

        return CustomerSearchResult(
          success: true,
          customer: localCustomer,
          source: 'Local Database',
          message: 'Customer found (Offline)',
          meterInfoCheck: meterInfoCheck,
        );
      }

      // STEP 2: Not found in local DB, search online in SQL Server
      print('⚠️ Customer not found in local DB. Searching online...');
      return await _searchFromApi(oldConsumerId);
    } catch (e) {
      print('❌ Search error: $e');
      return CustomerSearchResult(
        success: false,
        source: 'Error',
        message: 'Error searching customer: $e',
      );
    }
  }

  // Search from API (online SQL Server search)
  Future<CustomerSearchResult> _searchFromApi(String oldConsumerId) async {
    try {
      print('🌐 Searching customer from API: $oldConsumerId');
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/customer/$oldConsumerId',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final customer = Customer.fromMap(response.data!);

        // Save to local database for future offline use
        await _dbService.createOrUpdateCustomer(customer);

        // Check if customer already has meter installed
        final meterInfoCheck = await checkMeterInfoDuplicate(oldConsumerId);

        print('✅ Customer found from API and saved to local DB');
        return CustomerSearchResult(
          success: true,
          customer: customer,
          source: 'API (Online)',
          message: 'Customer found online',
          meterInfoCheck: meterInfoCheck,
        );
      } else {
        print('❌ Customer not found in API');
        return CustomerSearchResult(
          success: false,
          source: 'API',
          message: response.message.isEmpty
              ? 'Customer not found'
              : response.message,
        );
      }
    } catch (e) {
      print('❌ API Error: $e');
      return CustomerSearchResult(
        success: false,
        source: 'API',
        message: 'Unable to search online. Please check your internet connection.',
      );
    }
  }

  // Search from local database
  Future<CustomerSearchResult> _searchFromLocalDatabase(String oldConsumerId) async {
    try {
      final customer = await _dbService.getCustomerByOldConsumerId(oldConsumerId);

      if (customer != null) {
        print('✅ Customer found in local database');
        return CustomerSearchResult(
          success: true,
          customer: customer,
          source: 'Local Database',
          message: 'Customer found (Offline)',
        );
      } else {
        print('❌ Customer not found in local database');
        return CustomerSearchResult(
          success: false,
          source: 'Local Database',
          message: 'Customer not found. Please sync customer data or check the ID.',
        );
      }
    } catch (e) {
      print('❌ Local database error: $e');
      return CustomerSearchResult(
        success: false,
        source: 'Local Database',
        message: 'Error searching customer: $e',
      );
    }
  }

  // Sync all customers from server to local database
  Future<CustomerSyncResult> syncCustomers({int? limit, int? offset}) async {
    try {
      print('🔄 Syncing customers from server...');

      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/customers/sync',
        queryParameters: queryParams,
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final customersList = data['customers'] as List<dynamic>;
        final total = data['total'] as int? ?? 0;
        final synced = data['synced'] as int? ?? 0;

        final customers = customersList
            .map((json) => Customer.fromMap(json as Map<String, dynamic>))
            .toList();

        // Bulk insert to local database
        final insertedCount = await _dbService.bulkInsertCustomers(customers);

        print('✅ Synced $insertedCount customers to local database');
        return CustomerSyncResult(
          success: true,
          syncedCount: insertedCount,
          totalCount: total,
          message: 'Synced $insertedCount of $total customers',
        );
      } else {
        return CustomerSyncResult(
          success: false,
          syncedCount: 0,
          totalCount: 0,
          message: response.message,
        );
      }
    } catch (e) {
      print('❌ Sync error: $e');
      return CustomerSyncResult(
        success: false,
        syncedCount: 0,
        totalCount: 0,
        message: 'Error syncing customers: $e',
      );
    }
  }

  // Get customer count from local database
  Future<int> getLocalCustomerCount() async {
    return await _dbService.getCustomerCount();
  }

  // Clear all local customers
  Future<bool> clearLocalCustomers() async {
    return await _dbService.deleteAllCustomers();
  }

  // Sync last 5000 customers in batches
  Future<CustomerSyncResult> syncCustomersInBatches({
    int batchSize = 100,
    Function(int synced, int total)? onProgress,
  }) async {
    try {
      print('🔄 Starting sync of last 5000 customers...');

      // First, get count of last 5000 customers
      final countResponse = await _apiClient.get<Map<String, dynamic>>(
        '/customers/count',
        requiresAuth: true,
      );

      if (!countResponse.success || countResponse.data == null) {
        return CustomerSyncResult(
          success: false,
          syncedCount: 0,
          totalCount: 0,
          message: 'Failed to get customer count',
        );
      }

      // Get the last 5000 count (not total count)
      final totalCustomers = countResponse.data!['last5000'] as int? ??
                            countResponse.data!['count'] as int;
      int syncedCount = 0;

      print('📊 Syncing $totalCustomers customers (Last 5000)');

      // Clear existing customers before syncing new ones
      await _dbService.deleteAllCustomers();
      print('🗑️ Cleared old customer data');

      // Sync in batches
      for (int offset = 0; offset < totalCustomers; offset += batchSize) {
        final result = await syncCustomers(limit: batchSize, offset: offset);

        if (result.success) {
          syncedCount += result.syncedCount;
          onProgress?.call(syncedCount, totalCustomers);
          print('📥 Synced batch: $syncedCount/$totalCustomers');
        } else {
          print('⚠️ Batch sync failed at offset $offset');
        }
      }

      print('✅ Sync completed: $syncedCount of $totalCustomers customers (Last 5000)');
      return CustomerSyncResult(
        success: true,
        syncedCount: syncedCount,
        totalCount: totalCustomers,
        message: 'Successfully synced $syncedCount customers (Last 5000 for offline use)',
      );
    } catch (e) {
      print('❌ Batch sync error: $e');
      return CustomerSyncResult(
        success: false,
        syncedCount: 0,
        totalCount: 0,
        message: 'Error during batch sync: $e',
      );
    }
  }
}

class CustomerSearchResult {
  final bool success;
  final Customer? customer;
  final String source;
  final String message;
  final MeterInfoCheckResult? meterInfoCheck;

  CustomerSearchResult({
    required this.success,
    this.customer,
    required this.source,
    required this.message,
    this.meterInfoCheck,
  });

  /// Returns true if customer is eligible for new CMO
  bool get isEligibleForCMO {
    if (meterInfoCheck == null) return true; // If check not performed, allow
    return meterInfoCheck!.isEligibleForCMO;
  }

  /// Returns true if customer already has meter installed
  bool get hasExistingInstallation {
    if (meterInfoCheck == null) return false;
    return meterInfoCheck!.hasExistingInstallation;
  }
}

class CustomerSyncResult {
  final bool success;
  final int syncedCount;
  final int totalCount;
  final String message;

  CustomerSyncResult({
    required this.success,
    required this.syncedCount,
    required this.totalCount,
    required this.message,
  });
}
