import 'package:latlong2/latlong.dart';

class Yayasan {
  final String name;
  final String address;
  final double lat;
  final double lon;
  final double? distance;
  final double? rating;
  final int? stars;

  Yayasan({
    required this.name,
    required this.address,
    required this.lat,
    required this.lon,
    this.distance,
    this.rating,
    this.stars,
  });

  LatLng get position => LatLng(lat, lon);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Yayasan &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          (lat - other.lat).abs() < 0.0001 &&
          (lon - other.lon).abs() < 0.0001;

  @override
  int get hashCode => name.hashCode ^ (lat * 10000).round() ^ (lon * 10000).round();
} 