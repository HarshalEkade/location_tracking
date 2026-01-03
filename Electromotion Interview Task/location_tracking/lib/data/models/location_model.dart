class LocationModel {
  final String id;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? userId;
  final String? sessionId;

  LocationModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.userId,
    this.sessionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'sessionId': sessionId,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'sessionId': sessionId,
    };
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      id: map['id'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      timestamp: DateTime.parse(map['timestamp'] as String),
      userId: map['userId'] as String?,
      sessionId: map['sessionId'] as String?,
    );
  }

  factory LocationModel.fromFirestore(Map<String, dynamic> map, String id) {
    return LocationModel(
      id: id,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      timestamp: DateTime.parse(map['timestamp'] as String),
      userId: map['userId'] as String?,
      sessionId: map['sessionId'] as String?,
    );
  }

  LocationModel copyWith({
    String? id,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    String? userId,
    String? sessionId,
  }) {
    return LocationModel(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}





