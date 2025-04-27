import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:clustering_google_maps/geohash.dart';

class FakePoint {
  static const tblFakePoints = "fake_points";
  static const dbId = "id";
  static const dbGeohash = "geohash";
  static const dbLat = "lat";
  static const dbLong = "long";

  final LatLng location;
  final String id;
  late String geohash;

  FakePoint({required this.location, required this.id}) {
    geohash = Geohash.encode(location.latitude, location.longitude);
  }

  FakePoint.fromMap(Map<String, dynamic> map)
      : location = LatLng(map['lat'], map['long']),
        id = map['id'] {
    geohash = Geohash.encode(location.latitude, location.longitude);
  }

  Map<String, dynamic> toMap() {
    return {
      dbId: id,
      dbGeohash: geohash,
      dbLat: location.latitude,
      dbLong: location.longitude,
    };
  }
}
