import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'constants.dart';
import 'models.dart';
import 'db_search.dart';

class TripMapPage extends StatefulWidget {
  final Trip trip;
  const TripMapPage({super.key, required this.trip});

  @override
  State<TripMapPage> createState() => _TripMapPageState();
}

class _TripMapPageState extends State<TripMapPage> {
  bool _loading = true;
  List<_RoutePoint> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _buildRoute();
  }

  Future<void> _buildRoute() async {
    final List<_RoutePoint> points = [];
    final Map<String, Map<String, double>?> cache = {};

    Future<Map<String, double>?> geocode(String stationId, String name) async {
      if (cache.containsKey(stationId)) return cache[stationId];
      final coords = await TrainApiService.geocodeById(stationId, name);
      cache[stationId] = coords;
      return coords;
    }

    for (int i = 0; i < widget.trip.destinations.length; i++) {
      final dest = widget.trip.destinations[i];
      final trains = dest.trains ?? [];
      final flights = dest.flights ?? [];
        for (final train in trains) {
          final fromCoords = await geocode(train.startId, train.start);
          final toCoords   = await geocode(train.endId,   train.end);
          if (fromCoords != null) {
            points.add(_RoutePoint(name: train.start, lat: fromCoords['lat']!, lng: fromCoords['lng']!, isStation: true));
          }
          if (toCoords != null) {
            points.add(_RoutePoint(name: train.end, lat: toCoords['lat']!, lng: toCoords['lng']!, isStation: true));
          }
        }
        for (final flight in flights) {
          // Flights use free-text airports — geocode by name
          final fromCoords = await TrainApiService.geocodeCity(flight.start);
          final toCoords   = await TrainApiService.geocodeCity(flight.end);
          if (fromCoords != null) {
            points.add(_RoutePoint(name: flight.start, lat: fromCoords['lat']!, lng: fromCoords['lng']!, isStation: false));
          }
          if (toCoords != null) {
            points.add(_RoutePoint(name: flight.end, lat: toCoords['lat']!, lng: toCoords['lng']!, isStation: false));
          }
        }
    }

    if (mounted) setState(() { _routePoints = points; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final latLngs = _routePoints.map((p) => LatLng(p.lat, p.lng)).toList();
    final bounds = latLngs.length >= 2 ? LatLngBounds.fromPoints(latLngs) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip.name),
        backgroundColor: kNavy,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : latLngs.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No route to display yet.\nAdd trains or flights to your trip to see them on the map.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kSubtext),
                    ),
                  ),
                )
              : FlutterMap(
                  options: MapOptions(
                    initialCameraFit: bounds != null
                        ? CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60))
                        : CameraFit.coordinates(coordinates: latLngs, padding: const EdgeInsets.all(60)),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.interrail_planner',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: latLngs,
                          color: kAccent,
                          strokeWidth: 3.0,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        for (final point in _routePoints.where((p) => p.isStation))
                          Marker(
                            point: LatLng(point.lat, point.lng),
                            width: 140,
                            height: 56,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: point.isStation ? kAccent : kNavy,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                                  ),
                                  child: Text(
                                    point.name,
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  point.isStation ? Icons.train : Icons.location_on,
                                  color: point.isStation ? kAccent : kNavy,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
    );
  }
}

class _RoutePoint {
  final String name;
  final double lat, lng;
  final bool isStation;
  const _RoutePoint({required this.name, required this.lat, required this.lng, required this.isStation});
}