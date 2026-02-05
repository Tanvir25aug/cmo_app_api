import 'dart:io';
import '../models/cmo_model.dart';
import '../config/api_config.dart';
import 'api_client.dart';
import 'database_service.dart';
import 'auth_service.dart';

class CmoSyncService {
  static final CmoSyncService instance = CmoSyncService._internal();
  CmoSyncService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Sync a single CMO record to SQL Server
  Future<SyncResult> syncCMO(CMO cmo) async {
    try {
      // Get current user ID for MeterInstalledBy and CreateBy fields
      final currentUser = AuthService.instance.currentUser;
      final userId = _parseUserId(currentUser?.id);

      // First upload images if they exist
      // Meter images go to /uploads/meters folder
      // Seal images go to /uploads/seals folder
      String? oldMeterImageUrl;
      String? batterySealImageUrl;
      String? terminalSealImageUrl;

      if (cmo.oldMeterImagePath != null && cmo.oldMeterImagePath!.isNotEmpty) {
        oldMeterImageUrl = await _uploadImage(cmo.oldMeterImagePath!, 'meters');
      }

      if (cmo.batteryCoverSealImagePath != null && cmo.batteryCoverSealImagePath!.isNotEmpty) {
        batterySealImageUrl = await _uploadImage(cmo.batteryCoverSealImagePath!, 'seals');
      }

      if (cmo.terminalCoverSealImagePath != null && cmo.terminalCoverSealImagePath!.isNotEmpty) {
        terminalSealImageUrl = await _uploadImage(cmo.terminalCoverSealImagePath!, 'seals');
      }

      // Map CMO to SQL Server MeterInfo_test table structure
      final syncData = {
        'CustomerId': cmo.customerId,
        'OldConsumerId': cmo.customerId,
        'InstallDate': cmo.installDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'Latitude': cmo.newMeterLatitude,
        'Longitude': cmo.newMeterLongitude,
        'HasOldMeterNo': cmo.oldMeterNumber != null && cmo.oldMeterNumber!.isNotEmpty ? 1 : 0,
        'OldMeterNoImgUrl': oldMeterImageUrl,
        'OldMeterNoOCR': cmo.oldMeterNumber,
        'OldMeterNoOld': cmo.oldMeterNumber,
        'HasOldMeterReading': cmo.oldMeterReading != null && cmo.oldMeterReading!.isNotEmpty ? 1 : 0,
        'OldMeterReadingImgUrl': oldMeterImageUrl,
        'OldMeterReadingOCR': cmo.oldMeterReading,
        'OldMeterReadingOld': cmo.oldMeterReading,
        'OldMeterPeak': cmo.onPeak,
        'OldMeterOffPeak': cmo.offPeak,
        'OldMeterKVAR': cmo.kvar,
        'HasNewMeterNo': cmo.newMeterId != null && cmo.newMeterId!.isNotEmpty ? 1 : 0,
        'NewMeterNoImgUrl': null,
        'NewMeterNoOCR': cmo.newMeterId,
        'NewMeterNoOld': cmo.newMeterId,
        'IsNewMeterDuplicate': 0,
        'NewMeterType': cmo.oldMeterType,
        'NewMeterBillingType': null,
        'NewMeterConnectionType': null,
        'IsPVCWireInstall': 0,
        'PVCWireSpec': null,
        'PVCWireLength': null,
        'HasBatteryCoverSeal': cmo.batteryCoverSeal != null && cmo.batteryCoverSeal!.isNotEmpty ? 1 : 0,
        'BatteryCoverSealImgUrl': batterySealImageUrl,
        'BatteryCoverSealOCR': cmo.batteryCoverSeal,
        'BatteryCoverSealOld': cmo.batteryCoverSeal,
        'HasTerminalCoverSeal1': cmo.terminalSeal1 != null && cmo.terminalSeal1!.isNotEmpty ? 1 : 0,
        'TerminalCoverSealImgUrl1': terminalSealImageUrl,
        'TerminalCoverSealOCR1': cmo.terminalSeal1,
        'TerminalCoverSealOld1': cmo.terminalSeal1,
        'HasTerminalCoverSeal2': cmo.terminalSeal2 != null && cmo.terminalSeal2!.isNotEmpty ? 1 : 0,
        'TerminalCoverSealImgUrl2': terminalSealImageUrl,
        'TerminalCoverSealOCR2': cmo.terminalSeal2,
        'TerminalCoverSealOld2': cmo.terminalSeal2,
        'HasSteelBox': cmo.hasSteelBox ? 1 : 0,
        'IsSteelBoxRemove': 0,
        'SteelBoxRemoveUrl': null,
        'MeterInstalledBy': userId, // Send user ID (int), not username
        'HasRevisit': 0,
        'RevisitDt': null,
        'RectifyStatus': null,
        'RectifyMessage': null,
        'IsApproved': 0,
        'ApprovedBy': null,
        'ApprovedDate': null,
        'IsMDMEntry': 0,
        'IsAppsEntry': 1,
        'IsActive': 1,
        'CreateBy': userId, // Send user ID (int), not username
        'CreateDate': cmo.createdAt.toIso8601String(),
        'UpdateBy': null,
        'UpdateDate': null,
        'LocalId': cmo.id,
      };

      // Send to server - API expects an array of CMOs
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.cmoSync,
        body: {
          'CMOs': [syncData],  // Wrap in array as API expects
        },
      );

      if (response.success) {
        // Mark as synced in local database
        await DatabaseService.instance.markCMOAsSynced(cmo.id!);

        return SyncResult(
          success: true,
          message: 'CMO synced successfully',
          serverId: response.data?['id']?.toString(),
        );
      } else {
        // Parse detailed error from server response
        final errorMessage = _parseServerError(response.errors, response.message);
        return SyncResult(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Sync failed: ${e.toString()}',
      );
    }
  }

  /// Parse user ID from string to int, returns null if not valid
  int? _parseUserId(String? id) {
    if (id == null || id.isEmpty) return null;
    return int.tryParse(id);
  }

  /// Parse server error response to get readable error message
  String _parseServerError(dynamic errors, String defaultMessage) {
    if (errors == null) return defaultMessage;

    try {
      if (errors is Map) {
        // Check for failed array in errors
        final failed = errors['failed'];
        if (failed != null && failed is List && failed.isNotEmpty) {
          final firstError = failed[0];
          if (firstError is Map) {
            final errorMsg = firstError['error']?.toString()?.toLowerCase() ?? '';
            final customerId = firstError['customerId']?.toString();
            final newMeterId = firstError['newMeterId']?.toString();

            // Make error message more user-friendly
            String friendlyError = firstError['error']?.toString() ?? defaultMessage;

            if (errorMsg.contains('conversion failed') && errorMsg.contains('nvarchar')) {
              friendlyError = 'Server expects a numeric ID but received text. Please re-login and try again.';
            } else if (errorMsg.contains('duplicate') && errorMsg.contains('customer')) {
              friendlyError = 'Customer ID already exists on server. This customer already has a meter installed.';
            } else if (errorMsg.contains('duplicate') && errorMsg.contains('meter')) {
              friendlyError = 'Meter number already exists on server. This meter is already assigned to another customer.';
            } else if (errorMsg.contains('duplicate') || errorMsg.contains('unique') || errorMsg.contains('violation')) {
              friendlyError = 'Duplicate record found on server. This data already exists.';
            } else if (errorMsg.contains('foreign key')) {
              friendlyError = 'Related data not found on server. Please verify customer information.';
            } else if (errorMsg.contains('not found')) {
              friendlyError = 'Customer or meter data not found on server.';
            }

            // Build result message with identifiers
            String result = friendlyError;
            if (customerId != null && customerId.isNotEmpty) {
              result = 'Customer $customerId: $result';
            }
            if (newMeterId != null && newMeterId.isNotEmpty) {
              result = '$result\nMeter: $newMeterId';
            }

            return result;
          }
        }
      }
    } catch (e) {
      print('Error parsing server error: $e');
    }

    return defaultMessage;
  }

  /// Sync all uploaded CMOs that are not yet synced
  Future<BatchSyncResult> syncAllUploadedCMOs() async {
    try {
      final cmos = await DatabaseService.instance.getUploadedUnsyncedCMOs();

      if (cmos.isEmpty) {
        return BatchSyncResult(
          success: true,
          totalCount: 0,
          syncedCount: 0,
          failedCount: 0,
          message: 'No CMOs to sync',
        );
      }

      int syncedCount = 0;
      int failedCount = 0;
      List<String> errors = [];

      for (var cmo in cmos) {
        final result = await syncCMO(cmo);
        if (result.success) {
          syncedCount++;
        } else {
          failedCount++;
          errors.add('${cmo.customerName}: ${result.message}');
        }
      }

      return BatchSyncResult(
        success: failedCount == 0,
        totalCount: cmos.length,
        syncedCount: syncedCount,
        failedCount: failedCount,
        message: failedCount == 0
            ? 'All $syncedCount CMOs synced successfully'
            : '$syncedCount synced, $failedCount failed',
        errors: errors,
      );
    } catch (e) {
      return BatchSyncResult(
        success: false,
        totalCount: 0,
        syncedCount: 0,
        failedCount: 0,
        message: 'Sync failed: ${e.toString()}',
      );
    }
  }

  /// Upload image to server and return URL
  /// folder: 'meters' or 'seals' - determines which folder on server
  Future<String?> _uploadImage(String imagePath, String folder) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return null;
      }

      // Upload to /api/upload/:folder endpoint
      // Server saves to D:\Node_API\cmo-api-package\uploads\{folder}\
      final response = await _apiClient.uploadFile<Map<String, dynamic>>(
        '/upload/$folder',
        file,
        'image',
        additionalFields: {
          'folder': folder,
        },
      );

      if (response.success && response.data != null) {
        // Return the file URL/path from server response
        return response.data!['url'] as String? ?? response.data!['filePath'] as String?;
      }
      return null;
    } catch (e) {
      print('Image upload to $folder failed: $e');
      return null;
    }
  }
}

class SyncResult {
  final bool success;
  final String message;
  final String? serverId;

  SyncResult({
    required this.success,
    required this.message,
    this.serverId,
  });
}

class BatchSyncResult {
  final bool success;
  final int totalCount;
  final int syncedCount;
  final int failedCount;
  final String message;
  final List<String>? errors;

  BatchSyncResult({
    required this.success,
    required this.totalCount,
    required this.syncedCount,
    required this.failedCount,
    required this.message,
    this.errors,
  });
}
