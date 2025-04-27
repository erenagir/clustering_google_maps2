import 'package:clustering_google_maps/src/aggregated_points.dart';
import 'package:clustering_google_maps/src/lat_lang_geohash.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLngBounds;
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static Future<List<AggregatedPoints>> getAggregatedPoints({
    required Database database,
    required String dbTable,
    required String dbLatColumn,
    required String dbLongColumn,
    required String dbGeohashColumn,
    required int level,
    required LatLngBounds latLngBounds,
    String whereClause = "",
  }) async {
    assert(() {
      print("--------- START QUERY AGGREGATION");
      return true;
    }());
    try {
      final String boundingBoxClause = buildBoundingBoxClause(
        latLngBounds,
        dbLatColumn,
        dbLongColumn,
      );

      final newWhereClause = whereClause.isEmpty
          ? "WHERE $boundingBoxClause"
          : "$whereClause AND $boundingBoxClause";

      final query = '''
        SELECT COUNT(*) as n_marker, 
               AVG($dbLatColumn) as lat, 
               AVG($dbLongColumn) as long 
        FROM $dbTable 
        $newWhereClause 
        GROUP BY substr($dbGeohashColumn,1,$level);
      ''';

      assert(() {
        print(query);
        return true;
      }());

      final result = await database.rawQuery(query);

      List<AggregatedPoints> aggregatedPoints = result
          .map((item) => AggregatedPoints.fromMap(item, dbLatColumn, dbLongColumn))
          .toList();

      assert(() {
        print("--------- COMPLETE QUERY AGGREGATION");
        return true;
      }());

      return aggregatedPoints;
    } catch (e) {
      assert(() {
        print(e.toString());
        print("--------- COMPLETE QUERY AGGREGATION WITH ERROR");
        return true;
      }());
      return [];
    }
  }

  static Future<List<LatLngAndGeohash>> getPoints({
    required Database database,
    required String dbTable,
    required String dbLatColumn,
    required String dbLongColumn,
    String whereClause = "",
  }) async {
    try {
      final result = await database.rawQuery('''
        SELECT $dbLatColumn as lat, $dbLongColumn as long 
        FROM $dbTable 
        $whereClause;
      ''');

      List<LatLngAndGeohash> points = result
          .map((item) => LatLngAndGeohash.fromMap(item))
          .toList();

      assert(() {
        print("--------- COMPLETE QUERY");
        return true;
      }());

      return points;
    } catch (e) {
      assert(() {
        print(e.toString());
        return true;
      }());
      return [];
    }
  }

  static String buildBoundingBoxClause(
      LatLngBounds latLngBounds, String dbLat, String dbLong) {
    assert(() {
      print(latLngBounds.toString());
      return true;
    }());
    final double leftTopLatitude = latLngBounds.northeast.latitude;
    final double leftTopLongitude = latLngBounds.southwest.longitude;
    final double rightBottomLatitude = latLngBounds.southwest.latitude;
    final double rightBottomLongitude = latLngBounds.northeast.longitude;

    final latQuery = (leftTopLatitude > rightBottomLatitude)
        ? "($dbLat <= $leftTopLatitude AND $dbLat >= $rightBottomLatitude)"
        : "($dbLat <= $leftTopLatitude OR $dbLat >= $rightBottomLatitude)";

    final longQuery = (leftTopLongitude < rightBottomLongitude)
        ? "($dbLong >= $leftTopLongitude AND $dbLong <= $rightBottomLongitude)"
        : "($dbLong >= $leftTopLongitude OR $dbLong <= $rightBottomLongitude)";

    return "$latQuery AND $longQuery";
  }
}
