import 'package:example/app_db.dart';
import 'package:example/fake_point.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:clustering_google_maps/clustering_google_maps.dart' show LatLngAndGeohash, ClusteringHelper, AggregationSetup;

class HomeScreen extends StatefulWidget {
  final List<LatLngAndGeohash>? list;

  const HomeScreen({Key? key, this.list}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ClusteringHelper clusteringHelper;
  final CameraPosition initialCameraPosition =
      const CameraPosition(target: LatLng(0.0, 0.0), zoom: 0.0);

  Set<Marker> markers = {};

  void _onMapCreated(GoogleMapController mapController) async {
    print("onMapCreated");
    clusteringHelper.mapController = mapController;
    if (widget.list == null) {
      clusteringHelper.database = await AppDatabase.get().getDb();
    }
    clusteringHelper.updateMap();
  }

  void updateMarkers(Set<Marker> markers) {
    setState(() {
      this.markers = markers;
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.list != null) {
      initMemoryClustering();
    } else {
      initDatabaseClustering();
    }
  }

Future<void> initDatabaseClustering() async {
  clusteringHelper = ClusteringHelper.forDB(
    dbGeohashColumn: FakePoint.dbGeohash,
    dbLatColumn: FakePoint.dbLat,
    dbLongColumn: FakePoint.dbLong,
    dbTable: FakePoint.tblFakePoints,
    updateMarkers: updateMarkers,
    aggregationSetup: AggregationSetup(),
    database: await AppDatabase.get().getDb(), // EKLENDİ!
  );
}

  void initMemoryClustering() {
    clusteringHelper = ClusteringHelper.forMemory(
      list: widget.list!,
      updateMarkers: updateMarkers,
      aggregationSetup: AggregationSetup(markerSize: 150),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Clustering Example"),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: initialCameraPosition,
        markers: markers,
        onCameraMove: (newPosition) =>
            clusteringHelper.onCameraMove(newPosition, forceUpdate: false),
        onCameraIdle: clusteringHelper.onMapIdle,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(widget.list == null ? Icons.content_cut : Icons.update),
        onPressed: () {
          if (widget.list == null) {
            clusteringHelper.whereClause = "WHERE ${FakePoint.dbLat} > 42.6";
          }
          clusteringHelper.updateMap();
        },
      ),
    );
  }
}
