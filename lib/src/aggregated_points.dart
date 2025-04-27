import 'package:google_maps_flutter/google_maps_flutter.dart';

class AggregatedPoints {
  final LatLng location;
  final int count;
  late String bitmapAssetName; // 🛠️ "late" yapıldı ve yazım düzeltildi

  AggregatedPoints(this.location, this.count) {
    bitmapAssetName = getBitmapDescriptor();
  }

  AggregatedPoints.fromMap(
    Map<String, dynamic> map,
    String dbLatColumn,
    String dbLongColumn,
  )   : location = LatLng(
          (map[dbLatColumn] as num).toDouble(),
          (map[dbLongColumn] as num).toDouble(),
        ),
        count = map['n_marker'] {
    bitmapAssetName = getBitmapDescriptor();
  }

  String getBitmapDescriptor() {
    if (count < 10) {
      return "assets/images/m1.png";
    } else if (count < 25) {
      return "assets/images/m2.png";
    } else if (count < 50) {
      return "assets/images/m3.png";
    } else if (count < 100) {
      return "assets/images/m4.png";
    } else if (count < 500) {
      return "assets/images/m5.png";
    } else if (count < 1000) {
      return "assets/images/m6.png";
    } else {
      return "assets/images/m7.png";
    }
  }

  String getId() {
    return "${location.latitude}_${location.longitude}_$count";
  }
}
