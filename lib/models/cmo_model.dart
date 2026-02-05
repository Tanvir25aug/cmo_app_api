class CMO {
  final String? id;
  final String? customerId;
  final String? newMeterId;
  final String customerName;
  final String? flatNo;
  final String? floor;
  final String mobileNumber;
  final String? secondaryMobileNumber;
  final String? email;
  final String? nid;
  final String? nocs;
  final String? feeder;
  final String? billGroup;
  final String? sanctionLoad;
  final String? bookNumber;
  final String? tariff;
  final String? oldMeterType; // 1P or 3P
  final String? oldMeterCategory; // postpaid or prepaid
  final String? oldMeterNumber;
  final String? oldMeterImagePath;
  final String? oldMeterReading; // For postpaid: reading, for prepaid: taka
  final String? onPeak;
  final String? offPeak;
  final String? kvar;
  final String? newMeterImagePath;
  final double? newMeterLatitude;
  final double? newMeterLongitude;
  final DateTime? installDate;
  final String? batteryCoverSeal;
  final String? batteryCoverSealImagePath;
  final String? terminalSeal1;
  final String? terminalSeal2;
  final String? terminalCoverSealImagePath;
  final bool hasSteelBox;
  final String? installBy;
  final String status; // draft, pending, uploaded
  final bool isSynced;
  final DateTime? syncedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? userId;
  final String? bulkGroupId; // Reference to bulk CMO group
  final int? meterIndex; // Index in bulk group

  CMO({
    this.id,
    this.customerId,
    this.newMeterId,
    required this.customerName,
    this.flatNo,
    this.floor,
    required this.mobileNumber,
    this.secondaryMobileNumber,
    this.email,
    this.nid,
    this.nocs,
    this.feeder,
    this.billGroup,
    this.sanctionLoad,
    this.bookNumber,
    this.tariff,
    this.oldMeterType,
    this.oldMeterCategory,
    this.oldMeterNumber,
    this.oldMeterImagePath,
    this.oldMeterReading,
    this.onPeak,
    this.offPeak,
    this.kvar,
    this.newMeterImagePath,
    this.newMeterLatitude,
    this.newMeterLongitude,
    this.installDate,
    this.batteryCoverSeal,
    this.batteryCoverSealImagePath,
    this.terminalSeal1,
    this.terminalSeal2,
    this.terminalCoverSealImagePath,
    this.hasSteelBox = false,
    this.installBy,
    this.status = 'draft',
    this.isSynced = false,
    this.syncedAt,
    DateTime? createdAt,
    this.updatedAt,
    this.userId,
    this.bulkGroupId,
    this.meterIndex,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'new_meter_id': newMeterId,
      'customer_name': customerName,
      'flat_no': flatNo,
      'floor': floor,
      'mobile_number': mobileNumber,
      'secondary_mobile_number': secondaryMobileNumber,
      'email': email,
      'nid': nid,
      'nocs': nocs,
      'feeder': feeder,
      'bill_group': billGroup,
      'sanction_load': sanctionLoad,
      'book_number': bookNumber,
      'tariff': tariff,
      'old_meter_type': oldMeterType,
      'old_meter_category': oldMeterCategory,
      'old_meter_number': oldMeterNumber,
      'old_meter_image_path': oldMeterImagePath,
      'old_meter_reading': oldMeterReading,
      'on_peak': onPeak,
      'off_peak': offPeak,
      'kvar': kvar,
      'new_meter_image_path': newMeterImagePath,
      'new_meter_latitude': newMeterLatitude,
      'new_meter_longitude': newMeterLongitude,
      'install_date': installDate?.toIso8601String(),
      'battery_cover_seal': batteryCoverSeal,
      'battery_cover_seal_image_path': batteryCoverSealImagePath,
      'terminal_seal_1': terminalSeal1,
      'terminal_seal_2': terminalSeal2,
      'terminal_cover_seal_image_path': terminalCoverSealImagePath,
      'has_steel_box': hasSteelBox ? 1 : 0,
      'install_by': installBy,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'user_id': userId,
      'bulk_group_id': bulkGroupId,
      'meter_index': meterIndex,
    };
  }

  factory CMO.fromMap(Map<String, dynamic> map) {
    return CMO(
      id: map['id']?.toString(),
      customerId: map['customer_id']?.toString(),
      newMeterId: map['new_meter_id']?.toString(),
      customerName: map['customer_name'] ?? '',
      flatNo: map['flat_no']?.toString(),
      floor: map['floor']?.toString(),
      mobileNumber: map['mobile_number'] ?? '',
      secondaryMobileNumber: map['secondary_mobile_number']?.toString(),
      email: map['email']?.toString(),
      nid: map['nid']?.toString(),
      nocs: map['nocs']?.toString(),
      feeder: map['feeder']?.toString(),
      billGroup: map['bill_group']?.toString(),
      sanctionLoad: map['sanction_load']?.toString(),
      bookNumber: map['book_number']?.toString(),
      tariff: map['tariff']?.toString(),
      oldMeterType: map['old_meter_type']?.toString(),
      oldMeterCategory: map['old_meter_category']?.toString(),
      oldMeterNumber: map['old_meter_number']?.toString(),
      oldMeterImagePath: map['old_meter_image_path']?.toString(),
      oldMeterReading: map['old_meter_reading']?.toString(),
      onPeak: map['on_peak']?.toString(),
      offPeak: map['off_peak']?.toString(),
      kvar: map['kvar']?.toString(),
      newMeterImagePath: map['new_meter_image_path']?.toString(),
      newMeterLatitude: map['new_meter_latitude'] != null
          ? double.tryParse(map['new_meter_latitude'].toString())
          : null,
      newMeterLongitude: map['new_meter_longitude'] != null
          ? double.tryParse(map['new_meter_longitude'].toString())
          : null,
      installDate: map['install_date'] != null
          ? DateTime.parse(map['install_date'])
          : null,
      batteryCoverSeal: map['battery_cover_seal']?.toString(),
      batteryCoverSealImagePath: map['battery_cover_seal_image_path']?.toString(),
      terminalSeal1: map['terminal_seal_1']?.toString(),
      terminalSeal2: map['terminal_seal_2']?.toString(),
      terminalCoverSealImagePath: map['terminal_cover_seal_image_path']?.toString(),
      hasSteelBox: map['has_steel_box'] == 1 || map['has_steel_box'] == true,
      installBy: map['install_by']?.toString(),
      status: map['status'] ?? 'draft',
      isSynced: map['is_synced'] == 1 || map['is_synced'] == true,
      syncedAt: map['synced_at'] != null
          ? DateTime.parse(map['synced_at'])
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      userId: map['user_id'],
      bulkGroupId: map['bulk_group_id']?.toString(),
      meterIndex: map['meter_index'],
    );
  }

  CMO copyWith({
    String? id,
    String? customerId,
    String? newMeterId,
    String? customerName,
    String? flatNo,
    String? floor,
    String? mobileNumber,
    String? secondaryMobileNumber,
    String? email,
    String? nid,
    String? nocs,
    String? feeder,
    String? billGroup,
    String? sanctionLoad,
    String? bookNumber,
    String? tariff,
    String? oldMeterType,
    String? oldMeterCategory,
    String? oldMeterNumber,
    String? oldMeterImagePath,
    String? oldMeterReading,
    String? onPeak,
    String? offPeak,
    String? kvar,
    String? newMeterImagePath,
    double? newMeterLatitude,
    double? newMeterLongitude,
    DateTime? installDate,
    String? batteryCoverSeal,
    String? batteryCoverSealImagePath,
    String? terminalSeal1,
    String? terminalSeal2,
    String? terminalCoverSealImagePath,
    bool? hasSteelBox,
    String? installBy,
    String? status,
    bool? isSynced,
    DateTime? syncedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? userId,
    String? bulkGroupId,
    int? meterIndex,
  }) {
    return CMO(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      newMeterId: newMeterId ?? this.newMeterId,
      customerName: customerName ?? this.customerName,
      flatNo: flatNo ?? this.flatNo,
      floor: floor ?? this.floor,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      secondaryMobileNumber: secondaryMobileNumber ?? this.secondaryMobileNumber,
      email: email ?? this.email,
      nid: nid ?? this.nid,
      nocs: nocs ?? this.nocs,
      feeder: feeder ?? this.feeder,
      billGroup: billGroup ?? this.billGroup,
      sanctionLoad: sanctionLoad ?? this.sanctionLoad,
      bookNumber: bookNumber ?? this.bookNumber,
      tariff: tariff ?? this.tariff,
      oldMeterType: oldMeterType ?? this.oldMeterType,
      oldMeterCategory: oldMeterCategory ?? this.oldMeterCategory,
      oldMeterNumber: oldMeterNumber ?? this.oldMeterNumber,
      oldMeterImagePath: oldMeterImagePath ?? this.oldMeterImagePath,
      oldMeterReading: oldMeterReading ?? this.oldMeterReading,
      onPeak: onPeak ?? this.onPeak,
      offPeak: offPeak ?? this.offPeak,
      kvar: kvar ?? this.kvar,
      newMeterImagePath: newMeterImagePath ?? this.newMeterImagePath,
      newMeterLatitude: newMeterLatitude ?? this.newMeterLatitude,
      newMeterLongitude: newMeterLongitude ?? this.newMeterLongitude,
      installDate: installDate ?? this.installDate,
      batteryCoverSeal: batteryCoverSeal ?? this.batteryCoverSeal,
      batteryCoverSealImagePath: batteryCoverSealImagePath ?? this.batteryCoverSealImagePath,
      terminalSeal1: terminalSeal1 ?? this.terminalSeal1,
      terminalSeal2: terminalSeal2 ?? this.terminalSeal2,
      terminalCoverSealImagePath: terminalCoverSealImagePath ?? this.terminalCoverSealImagePath,
      hasSteelBox: hasSteelBox ?? this.hasSteelBox,
      installBy: installBy ?? this.installBy,
      status: status ?? this.status,
      isSynced: isSynced ?? this.isSynced,
      syncedAt: syncedAt ?? this.syncedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      bulkGroupId: bulkGroupId ?? this.bulkGroupId,
      meterIndex: meterIndex ?? this.meterIndex,
    );
  }
}
