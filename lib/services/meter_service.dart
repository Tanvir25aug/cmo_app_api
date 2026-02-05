import 'package:flutter/foundation.dart';
import '../models/meter_reading_model.dart';
import 'database_service.dart';

class MeterService extends ChangeNotifier {
  List<MeterReading> _readings = [];
  List<MeterReading> _unsyncedReadings = [];
  bool _isLoading = false;

  List<MeterReading> get readings => _readings;
  List<MeterReading> get unsyncedReadings => _unsyncedReadings;
  bool get isLoading => _isLoading;

  Future<void> loadReadings({String? userId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _readings = await DatabaseService.instance.getAllMeterReadings(userId: userId);
      _unsyncedReadings = await DatabaseService.instance.getUnsyncedReadings();
    } catch (e) {
      print('Error loading readings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addReading(MeterReading reading) async {
    try {
      final id = await DatabaseService.instance.createMeterReading(reading);
      if (id != null) {
        await loadReadings(userId: reading.userId);
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding reading: $e');
      return false;
    }
  }

  Future<bool> updateReading(MeterReading reading) async {
    try {
      final success = await DatabaseService.instance.updateMeterReading(reading);
      if (success) {
        await loadReadings(userId: reading.userId);
      }
      return success;
    } catch (e) {
      print('Error updating reading: $e');
      return false;
    }
  }

  Future<bool> deleteReading(String id) async {
    try {
      final success = await DatabaseService.instance.deleteMeterReading(id);
      if (success) {
        _readings.removeWhere((reading) => reading.id == id);
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error deleting reading: $e');
      return false;
    }
  }

  Future<List<MeterReading>> searchReadings(String query) async {
    try {
      return await DatabaseService.instance.searchMeterReadings(query);
    } catch (e) {
      print('Error searching readings: $e');
      return [];
    }
  }

  Future<void> syncReadings() async {
    // This would sync with a remote server in production
    // For offline mode, we'll just mark them as synced
    try {
      for (var reading in _unsyncedReadings) {
        final updatedReading = reading.copyWith(isSynced: true);
        await DatabaseService.instance.updateMeterReading(updatedReading);
      }
      await loadReadings();
    } catch (e) {
      print('Error syncing readings: $e');
    }
  }
}
