/// Model for grouping multiple CMOs in a bulk operation
/// Used when creating CMOs for multiple meters in a building/house
class BulkCMOGroup {
  final String? id;
  final String? buildingName;
  final String? buildingAddress;
  final double? latitude;
  final double? longitude;
  final String? feeder;
  final String? installBy;
  final int meterCount;
  final int completedCount;
  final String status; // draft, partial, complete, uploaded, synced
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? userId;

  BulkCMOGroup({
    this.id,
    this.buildingName,
    this.buildingAddress,
    this.latitude,
    this.longitude,
    this.feeder,
    this.installBy,
    this.meterCount = 0,
    this.completedCount = 0,
    this.status = 'draft',
    DateTime? createdAt,
    this.updatedAt,
    this.userId,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'building_name': buildingName,
      'building_address': buildingAddress,
      'latitude': latitude,
      'longitude': longitude,
      'feeder': feeder,
      'install_by': installBy,
      'meter_count': meterCount,
      'completed_count': completedCount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'user_id': userId,
    };
  }

  factory BulkCMOGroup.fromMap(Map<String, dynamic> map) {
    return BulkCMOGroup(
      id: map['id']?.toString(),
      buildingName: map['building_name']?.toString(),
      buildingAddress: map['building_address']?.toString(),
      latitude: map['latitude'] != null
          ? double.tryParse(map['latitude'].toString())
          : null,
      longitude: map['longitude'] != null
          ? double.tryParse(map['longitude'].toString())
          : null,
      feeder: map['feeder']?.toString(),
      installBy: map['install_by']?.toString(),
      meterCount: map['meter_count'] ?? 0,
      completedCount: map['completed_count'] ?? 0,
      status: map['status'] ?? 'draft',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      userId: map['user_id'],
    );
  }

  BulkCMOGroup copyWith({
    String? id,
    String? buildingName,
    String? buildingAddress,
    double? latitude,
    double? longitude,
    String? feeder,
    String? installBy,
    int? meterCount,
    int? completedCount,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? userId,
  }) {
    return BulkCMOGroup(
      id: id ?? this.id,
      buildingName: buildingName ?? this.buildingName,
      buildingAddress: buildingAddress ?? this.buildingAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      feeder: feeder ?? this.feeder,
      installBy: installBy ?? this.installBy,
      meterCount: meterCount ?? this.meterCount,
      completedCount: completedCount ?? this.completedCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }

  /// Check if all meters are completed
  bool get isComplete => completedCount >= meterCount && meterCount > 0;

  /// Get completion percentage
  double get completionPercentage =>
      meterCount > 0 ? (completedCount / meterCount) * 100 : 0;

  /// Get status color
  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'partial':
        return 'In Progress';
      case 'complete':
        return 'Complete';
      case 'uploaded':
        return 'Uploaded';
      case 'synced':
        return 'Synced';
      default:
        return 'Unknown';
    }
  }
}

/// Model for individual meter entry in bulk CMO
class BulkMeterEntry {
  final String? id;
  final String? bulkGroupId;
  final int meterIndex;
  final String? customerId;
  final String? customerName;
  final String? flatNo;
  final String? floor;
  final String? trackingNumber; // Local tracking number for identification
  final String? newMeterId;
  final String? mobileNumber;
  final bool isComplete;
  final String? cmoId; // Reference to actual CMO record when created

  BulkMeterEntry({
    this.id,
    this.bulkGroupId,
    required this.meterIndex,
    this.customerId,
    this.customerName,
    this.flatNo,
    this.floor,
    this.trackingNumber,
    this.newMeterId,
    this.mobileNumber,
    this.isComplete = false,
    this.cmoId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bulk_group_id': bulkGroupId,
      'meter_index': meterIndex,
      'customer_id': customerId,
      'customer_name': customerName,
      'flat_no': flatNo,
      'floor': floor,
      'tracking_number': trackingNumber,
      'new_meter_id': newMeterId,
      'mobile_number': mobileNumber,
      'is_complete': isComplete ? 1 : 0,
      'cmo_id': cmoId,
    };
  }

  factory BulkMeterEntry.fromMap(Map<String, dynamic> map) {
    return BulkMeterEntry(
      id: map['id']?.toString(),
      bulkGroupId: map['bulk_group_id']?.toString(),
      meterIndex: map['meter_index'] ?? 0,
      customerId: map['customer_id']?.toString(),
      customerName: map['customer_name']?.toString(),
      flatNo: map['flat_no']?.toString(),
      floor: map['floor']?.toString(),
      trackingNumber: map['tracking_number']?.toString(),
      newMeterId: map['new_meter_id']?.toString(),
      mobileNumber: map['mobile_number']?.toString(),
      isComplete: map['is_complete'] == 1 || map['is_complete'] == true,
      cmoId: map['cmo_id']?.toString(),
    );
  }

  BulkMeterEntry copyWith({
    String? id,
    String? bulkGroupId,
    int? meterIndex,
    String? customerId,
    String? customerName,
    String? flatNo,
    String? floor,
    String? trackingNumber,
    String? newMeterId,
    String? mobileNumber,
    bool? isComplete,
    String? cmoId,
  }) {
    return BulkMeterEntry(
      id: id ?? this.id,
      bulkGroupId: bulkGroupId ?? this.bulkGroupId,
      meterIndex: meterIndex ?? this.meterIndex,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      flatNo: flatNo ?? this.flatNo,
      floor: floor ?? this.floor,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      newMeterId: newMeterId ?? this.newMeterId,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      isComplete: isComplete ?? this.isComplete,
      cmoId: cmoId ?? this.cmoId,
    );
  }

  /// Get display name for the meter
  String get displayName {
    if (trackingNumber != null && trackingNumber!.isNotEmpty) {
      return trackingNumber!;
    }
    if (flatNo != null && flatNo!.isNotEmpty) {
      return 'Flat $flatNo';
    }
    if (floor != null && floor!.isNotEmpty) {
      return 'Floor $floor';
    }
    return 'Meter $meterIndex';
  }
}
