/// Model for checking if a customer already has meter installation (CMO completed)
/// This is used to prevent duplicate CMO entries
class MeterInfoCheckResult {
  final bool exists; // true if customer found in MeterInfo table
  final bool isDuplicate; // true if customer already has CMO completed
  final String? customerId;
  final String? oldConsumerId;
  final String? newMeterNo;
  final DateTime? installDate;
  final String message;

  MeterInfoCheckResult({
    required this.exists,
    required this.isDuplicate,
    this.customerId,
    this.oldConsumerId,
    this.newMeterNo,
    this.installDate,
    required this.message,
  });

  factory MeterInfoCheckResult.fromJson(Map<String, dynamic> json) {
    return MeterInfoCheckResult(
      exists: json['exists'] as bool? ?? false,
      isDuplicate: json['isDuplicate'] as bool? ?? false,
      customerId: json['customerId']?.toString(),
      oldConsumerId: json['oldConsumerId']?.toString(),
      newMeterNo: json['newMeterNo']?.toString(),
      installDate: json['installDate'] != null
          ? DateTime.parse(json['installDate'])
          : null,
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exists': exists,
      'isDuplicate': isDuplicate,
      'customerId': customerId,
      'oldConsumerId': oldConsumerId,
      'newMeterNo': newMeterNo,
      'installDate': installDate?.toIso8601String(),
      'message': message,
    };
  }

  /// Returns true if customer is eligible for new CMO (not in MeterInfo)
  bool get isEligibleForCMO => !isDuplicate && !exists;

  /// Returns true if customer already has a meter installed
  bool get hasExistingInstallation => exists && isDuplicate;
}
