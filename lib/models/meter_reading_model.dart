class MeterReading {
  final String? id;
  final String meterNumber;
  final String reading;
  final String? previousReading;
  final String? consumerName;
  final String? consumerAddress;
  final String? meterType; // Electric, Gas, Water
  final String imagePath;
  final double? latitude;
  final double? longitude;
  final DateTime readingDate;
  final bool isSynced;
  final String? remarks;
  final String? userId;

  MeterReading({
    this.id,
    required this.meterNumber,
    required this.reading,
    this.previousReading,
    this.consumerName,
    this.consumerAddress,
    this.meterType,
    required this.imagePath,
    this.latitude,
    this.longitude,
    required this.readingDate,
    this.isSynced = false,
    this.remarks,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'meterNumber': meterNumber,
      'reading': reading,
      'previousReading': previousReading,
      'consumerName': consumerName,
      'consumerAddress': consumerAddress,
      'meterType': meterType,
      'imagePath': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'readingDate': readingDate.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'remarks': remarks,
      'userId': userId,
    };
  }

  factory MeterReading.fromMap(Map<String, dynamic> map) {
    return MeterReading(
      id: map['id'],
      meterNumber: map['meterNumber'],
      reading: map['reading'],
      previousReading: map['previousReading'],
      consumerName: map['consumerName'],
      consumerAddress: map['consumerAddress'],
      meterType: map['meterType'],
      imagePath: map['imagePath'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      readingDate: DateTime.parse(map['readingDate']),
      isSynced: map['isSynced'] == 1,
      remarks: map['remarks'],
      userId: map['userId'],
    );
  }

  MeterReading copyWith({
    String? id,
    String? meterNumber,
    String? reading,
    String? previousReading,
    String? consumerName,
    String? consumerAddress,
    String? meterType,
    String? imagePath,
    double? latitude,
    double? longitude,
    DateTime? readingDate,
    bool? isSynced,
    String? remarks,
    String? userId,
  }) {
    return MeterReading(
      id: id ?? this.id,
      meterNumber: meterNumber ?? this.meterNumber,
      reading: reading ?? this.reading,
      previousReading: previousReading ?? this.previousReading,
      consumerName: consumerName ?? this.consumerName,
      consumerAddress: consumerAddress ?? this.consumerAddress,
      meterType: meterType ?? this.meterType,
      imagePath: imagePath ?? this.imagePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      readingDate: readingDate ?? this.readingDate,
      isSynced: isSynced ?? this.isSynced,
      remarks: remarks ?? this.remarks,
      userId: userId ?? this.userId,
    );
  }

  double get consumption {
    if (previousReading != null && previousReading!.isNotEmpty) {
      try {
        return double.parse(reading) - double.parse(previousReading!);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }
}
