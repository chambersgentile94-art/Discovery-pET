class AnimalReport {
  const AnimalReport({
    this.id,
    required this.animalType,
    required this.category,
    required this.title,
    required this.description,
    required this.status,
    required this.urgency,
    required this.latitude,
    required this.longitude,
    this.approximateAddress,
  });

  final String? id;
  final String animalType;
  final String category;
  final String title;
  final String description;
  final String status;
  final String urgency;
  final double latitude;
  final double longitude;
  final String? approximateAddress;

  factory AnimalReport.fromMap(Map<String, dynamic> map) {
    return AnimalReport(
      id: map['id'] as String?,
      animalType: map['animal_type'] as String,
      category: map['category'] as String,
      title: map['title'] as String,
      description: (map['description'] ?? '') as String,
      status: map['status'] as String,
      urgency: map['urgency'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      approximateAddress: map['approximate_address'] as String?,
    );
  }

  Map<String, dynamic> toInsertMap({required String createdBy}) {
    return {
      'created_by': createdBy,
      'animal_type': animalType,
      'category': category,
      'title': title,
      'description': description,
      'status': status,
      'urgency': urgency,
      'latitude': latitude,
      'longitude': longitude,
      'approximate_address': approximateAddress,
    };
  }
}
