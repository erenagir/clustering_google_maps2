import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import '../geohash.dart';

class LatLngAndGeohash {
  final LatLng location;
  final String geohash;

  LatLngAndGeohash(this.location)
      : geohash = Geohash.encode(location.latitude, location.longitude);

  LatLngAndGeohash.fromMap(Map<String, dynamic> map)
      : location = LatLng(map['lat'], map['long']),
        geohash = Geohash.encode(map['lat'], map['long']);

  String getId() {
    return "${location.latitude}_${location.longitude}_${Random().nextInt(10000)}";
  }
}
