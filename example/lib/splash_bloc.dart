import 'dart:convert';
import 'package:clustering_google_maps/clustering_google_maps.dart';
import 'package:example/app_db.dart';
import 'package:example/fake_point.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sqflite/sqflite.dart';

class SplashBloc {
  Future<List<LatLngAndGeohash>> getListOfLatLngAndGeohash(
      BuildContext context) async {
    print("START GET FAKE DATA");
    try {
      final fakeList = await loadDataFromJson(context);
      List<LatLngAndGeohash> myPoints = <LatLngAndGeohash>[];
      for (int i = 0; i < fakeList.length; i++) {
        final fakePoint = fakeList[i];
        final p = LatLngAndGeohash(
          LatLng(
            (fakePoint["LATITUDE"] as num).toDouble(),
            (fakePoint["LONGITUDE"] as num).toDouble(),
          ),
        );
        myPoints.add(p);
      }
      print("EXTRACT COMPLETE");
      return myPoints;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> addFakePointsToDB(BuildContext context) async {
    print("START GET FAKE DATA");
    try {
      final fakeList = await loadDataFromJson(context);
      for (int i = 0; i < fakeList.length; i++) {
        final point = fakeList[i];
        final f = FakePoint(
          location: LatLng(
            (point["LATITUDE"] as num).toDouble(),
            (point["LONGITUDE"] as num).toDouble(),
          ),
          id: i.toString(), // 🔥 id artık String olmalı!
        );
        await saveFakePointToDB(f);
      }
      print("EXTRACT COMPLETE");
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<List<dynamic>> loadDataFromJson(BuildContext context) async {
    final fakeData = await DefaultAssetBundle.of(context)
        .loadString('assets/map_point.json');
    return json.decode(fakeData) as List<dynamic>;
  }

  Future<void> saveFakePointToDB(FakePoint fakePoint) async {
    var db = await AppDatabase.get().getDb();
    try {
      await db.transaction((Transaction txn) async {
        await txn.rawInsert('INSERT INTO '
            '${FakePoint.tblFakePoints}(${FakePoint.dbGeohash},${FakePoint.dbLat},${FakePoint.dbLong}) '
            'VALUES("${fakePoint.geohash}", ${fakePoint.location.latitude}, ${fakePoint.location.longitude})');
      });
    } catch (e) {
      print("Error = ${e.toString()}");
      throw Exception(e);
    }
  }
}
