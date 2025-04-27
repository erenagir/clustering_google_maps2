import 'dart:typed_data';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:clustering_google_maps/src/aggregated_points.dart';
import 'package:clustering_google_maps/src/aggregation_setup.dart';
import 'package:clustering_google_maps/src/db_helper.dart';
import 'package:clustering_google_maps/src/lat_lang_geohash.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sqflite/sqflite.dart';

class ClusteringHelper {
  late Database database;
  late String dbTable;
  late String dbLatColumn;
  late String dbLongColumn;
  late String dbGeohashColumn;
  String whereClause = "";
  late GoogleMapController mapController;
  late Function(Set<Marker>) updateMarkers;
  late AggregationSetup aggregationSetup;
  late List<LatLngAndGeohash> list;
  Function? showSinglePoint;
  String? bitmapAssetPathForSingleMarker;
  final double maxZoomForAggregatePoints;

  ClusteringHelper.forDB({
    required this.dbTable,
    required this.dbLatColumn,
    required this.dbLongColumn,
    required this.dbGeohashColumn,
    required this.updateMarkers,
    required this.aggregationSetup,
    required this.database,
    this.whereClause = "",
    this.maxZoomForAggregatePoints = 13.5,
    this.bitmapAssetPathForSingleMarker,
  });

  ClusteringHelper.forMemory({
    required this.list,
    required this.updateMarkers,
    required this.aggregationSetup,
    this.maxZoomForAggregatePoints = 13.5,
    this.bitmapAssetPathForSingleMarker,
  });

  double _currentZoom = 0.0;

  void onCameraMove(CameraPosition position, {bool forceUpdate = false}) {
    _currentZoom = position.zoom;
    if (forceUpdate) {
      updateMap();
    }
  }

  Future<void> onMapIdle() async {
    updateMap();
  }

  void updateMap() {
    if (_currentZoom < maxZoomForAggregatePoints) {
      updateAggregatedPoints(zoom: _currentZoom);
    } else {
      if (showSinglePoint != null) {
        showSinglePoint!();
      } else {
        updatePoints(_currentZoom);
      }
    }
  }

  void updateData(List<LatLngAndGeohash> newList) {
    list = newList;
    updateMap();
  }

  Future<List<AggregatedPoints>> getAggregatedPoints(double zoom) async {
    int level = 5;
    if (zoom <= aggregationSetup.maxZoomLimits[0]) {
      level = 1;
    } else if (zoom < aggregationSetup.maxZoomLimits[1]) {
      level = 2;
    } else if (zoom < aggregationSetup.maxZoomLimits[2]) {
      level = 3;
    } else if (zoom < aggregationSetup.maxZoomLimits[3]) {
      level = 4;
    } else if (zoom < aggregationSetup.maxZoomLimits[4]) {
      level = 5;
    } else if (zoom < aggregationSetup.maxZoomLimits[5]) {
      level = 6;
    } else if (zoom < aggregationSetup.maxZoomLimits[6]) {
      level = 7;
    }

    try {
      List<AggregatedPoints> aggregatedPoints;
      final latLngBounds = await mapController.getVisibleRegion();
      if (database != null) {
        aggregatedPoints = await DBHelper.getAggregatedPoints(
          database: database,
          dbTable: dbTable,
          dbLatColumn: dbLatColumn,
          dbLongColumn: dbLongColumn,
          dbGeohashColumn: dbGeohashColumn,
          level: level,
          latLngBounds: latLngBounds,
          whereClause: whereClause,
        );
      } else {
        final listBounds = list.where((p) {
          final leftTopLatitude = latLngBounds.northeast.latitude;
          final leftTopLongitude = latLngBounds.southwest.longitude;
          final rightBottomLatitude = latLngBounds.southwest.latitude;
          final rightBottomLongitude = latLngBounds.northeast.longitude;

          final latQuery = (leftTopLatitude > rightBottomLatitude)
              ? (p.location.latitude <= leftTopLatitude &&
                  p.location.latitude >= rightBottomLatitude)
              : (p.location.latitude <= leftTopLatitude ||
                  p.location.latitude >= rightBottomLatitude);

          final longQuery = (leftTopLongitude < rightBottomLongitude)
              ? (p.location.longitude >= leftTopLongitude &&
                  p.location.longitude <= rightBottomLongitude)
              : (p.location.longitude >= leftTopLongitude ||
                  p.location.longitude <= rightBottomLongitude);

          return latQuery && longQuery;
        }).toList();

        aggregatedPoints = _retrieveAggregatedPoints(listBounds, <AggregatedPoints>[], level);
      }
      return aggregatedPoints;
    } catch (e) {
      print(e.toString());
      return <AggregatedPoints>[];
    }
  }

  List<AggregatedPoints> _retrieveAggregatedPoints(
      List<LatLngAndGeohash> inputList,
      List<AggregatedPoints> resultList,
      int level) {
    if (inputList.isEmpty) return resultList;

    final newInputList = List<LatLngAndGeohash>.from(inputList);
    final t = newInputList[0].geohash.substring(0, level);
    final tmp = newInputList.where((p) => p.geohash.substring(0, level) == t).toList();
    newInputList.removeWhere((p) => p.geohash.substring(0, level) == t);

    double latitude = 0;
    double longitude = 0;
    for (var l in tmp) {
      latitude += l.location.latitude;
      longitude += l.location.longitude;
    }

    final count = tmp.length;
    final a = AggregatedPoints(LatLng(latitude / count, longitude / count), count);
    resultList.add(a);

    return _retrieveAggregatedPoints(newInputList, resultList, level);
  }

  Future<void> updateAggregatedPoints({double zoom = 0.0}) async {
    final aggregation = await getAggregatedPoints(zoom);
    final markers = <Marker>{};

    for (var a in aggregation) {
      BitmapDescriptor bitmapDescriptor;

      if (a.count == 1) {
        if (bitmapAssetPathForSingleMarker != null) {
          bitmapDescriptor = await BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(),
            bitmapAssetPathForSingleMarker!,
          );
        } else {
          bitmapDescriptor = BitmapDescriptor.defaultMarker;
        }
      } else {
        final markerIcon = await getBytesFromCanvas(a.count.toString(), getColor(a.count));
        bitmapDescriptor = BitmapDescriptor.fromBytes(markerIcon);
      }

      final markerId = MarkerId(a.getId());
      final marker = Marker(
        markerId: markerId,
        position: a.location,
        infoWindow: InfoWindow(title: a.count.toString()),
        icon: bitmapDescriptor,
      );

      markers.add(marker);
    }

    updateMarkers(markers);
  }

  Future<void> updatePoints(double zoom) async {
    try {
      List<LatLngAndGeohash> listOfPoints;
      if (database != null) {
        listOfPoints = await DBHelper.getPoints(
          database: database,
          dbTable: dbTable,
          dbLatColumn: dbLatColumn,
          dbLongColumn: dbLongColumn,
          whereClause: whereClause,
        );
      } else {
        listOfPoints = list;
      }

      final markers = listOfPoints.map((p) {
        final markerId = MarkerId(p.getId());
        return Marker(
          markerId: markerId,
          position: p.location,
          infoWindow: InfoWindow(
            title: "${p.location.latitude.toStringAsFixed(2)},${p.location.longitude.toStringAsFixed(2)}",
          ),
          icon: bitmapAssetPathForSingleMarker != null
              ? BitmapDescriptor.defaultMarker
              : BitmapDescriptor.defaultMarker,
        );
      }).toSet();

      updateMarkers(markers);
    } catch (ex) {
      print(ex.toString());
    }
  }

  Future<Uint8List> getBytesFromCanvas(String text, MaterialColor color) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final size = aggregationSetup.markerSize;

    final paint1 = Paint()..color = color[400]!;
    final paint2 = Paint()..color = color[300]!;
    final paint3 = Paint()..color = color[100]!;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.0, paint3);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.4, paint2);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 3.3, paint1);

    final painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: text,
      style: TextStyle(fontSize: size / 4, color: Colors.black, fontWeight: FontWeight.bold),
    );
    painter.layout();
    painter.paint(
      canvas,
      Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
    );

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  MaterialColor getColor(int count) {
    if (count < aggregationSetup.maxAggregationItems[0]) {
      return aggregationSetup.colors[0];
    } else if (count < aggregationSetup.maxAggregationItems[1]) {
      return aggregationSetup.colors[1];
    } else if (count < aggregationSetup.maxAggregationItems[2]) {
      return aggregationSetup.colors[2];
    } else if (count < aggregationSetup.maxAggregationItems[3]) {
      return aggregationSetup.colors[3];
    } else if (count < aggregationSetup.maxAggregationItems[4]) {
      return aggregationSetup.colors[4];
    } else if (count < aggregationSetup.maxAggregationItems[5]) {
      return aggregationSetup.colors[5];
    } else {
      return aggregationSetup.colors[6];
    }
  }
}
