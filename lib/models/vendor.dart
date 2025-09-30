class Vendor {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final bool isNearby;
  final String? distance;
  final String? duration;

  const Vendor({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.isNearby = false,
    this.distance,
    this.duration
  });

  Vendor copyWith({bool? isNearby, String? distance, String? duration}) {
    return Vendor(
      id: id,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      isNearby: isNearby ?? this.isNearby,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration
    );
  }

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['S. No.'] as int,
      name: (json['Vendor Name'] as String?)?.trim() ?? 'Unknown Vendor',
      address: (json['Address'] as String?)?.trim() ?? '',
      latitude: _toDouble(json['Latitude']),
      longitude: _toDouble(json['Longitude']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
