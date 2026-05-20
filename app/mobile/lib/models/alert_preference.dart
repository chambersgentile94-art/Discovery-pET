class AlertPreference {
  const AlertPreference({
    this.id,
    required this.userId,
    this.city,
    this.latitude,
    this.longitude,
    required this.radiusKm,
    required this.notifyLost,
    required this.notifySeen,
    required this.notifyAbandoned,
    required this.notifyInjured,
    required this.notifyAdoption,
    required this.isEnabled,
  });

  final String? id;
  final String userId;
  final String? city;
  final double? latitude;
  final double? longitude;
  final double radiusKm;
  final bool notifyLost;
  final bool notifySeen;
  final bool notifyAbandoned;
  final bool notifyInjured;
  final bool notifyAdoption;
  final bool isEnabled;

  factory AlertPreference.fromMap(Map<String, dynamic> map) {
    return AlertPreference(
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      city: map['city'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      radiusKm: ((map['radius_km'] ?? 5) as num).toDouble(),
      notifyLost: (map['notify_lost'] ?? true) as bool,
      notifySeen: (map['notify_seen'] ?? true) as bool,
      notifyAbandoned: (map['notify_abandoned'] ?? true) as bool,
      notifyInjured: (map['notify_injured'] ?? true) as bool,
      notifyAdoption: (map['notify_adoption'] ?? false) as bool,
      isEnabled: (map['is_enabled'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toUpsertMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'radius_km': radiusKm,
      'notify_lost': notifyLost,
      'notify_seen': notifySeen,
      'notify_abandoned': notifyAbandoned,
      'notify_injured': notifyInjured,
      'notify_adoption': notifyAdoption,
      'is_enabled': isEnabled,
    };
  }
}
