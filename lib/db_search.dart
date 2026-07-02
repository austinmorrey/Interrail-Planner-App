import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class TrainApiService {
  static const _base = 'https://api.transitous.org/api/v1';

  // European country codes to filter out results from Brazil, USA etc.
  static const _europeanCountries = {
    'DE', 'FR', 'GB', 'IT', 'ES', 'NL', 'BE', 'AT', 'CH', 'PL',
    'CZ', 'SK', 'HU', 'HR', 'SI', 'RS', 'RO', 'BG', 'GR', 'PT',
    'SE', 'NO', 'DK', 'FI', 'EE', 'LV', 'LT', 'LU', 'IE', 'BA',
  };

  static Future<List<Map<String, String>>> searchStations(String query) async {
    if (query.length < 2) return [];

    final uri = Uri.parse('$_base/geocode')
        .replace(queryParameters: {'text': query});

    final res = await http.get(uri);
    if (res.statusCode != 200) return [];

    final List data = jsonDecode(res.body);

    return data
        .where((s) =>
            s['type'] == 'STOP' &&
            _europeanCountries.contains(s['country']))
        .take(8)
        .map<Map<String, String>>((s) => {
              'id': s['id'].toString(),
              'name': s['name'].toString(),
            })
        .toList();
  }

  static Future<Map<String, dynamic>> searchJourneys({
  required String fromId,
  required String toId,
  DateTime? when,
  String? earlierRef,
  String? laterRef,
  }) async {
    final Map<String, String> params = {
        'fromPlace': fromId,
        'toPlace': toId,
      };

      if (earlierRef != null) {
        params['pageCursor'] = earlierRef;
      } else if (laterRef != null) {
        params['pageCursor'] = laterRef;
      } else {
        final departure = (when ?? DateTime.now());
        // Transitous needs timezone offset format
        params['time'] = departure.toUtc().toIso8601String();
      }

      final uri = Uri.parse('$_base/plan').replace(queryParameters: params);
      print('Fetching: $uri');

      final res = await http.get(uri);
      print(res);
      if (res.statusCode != 200) {
        print('Error: ${res.statusCode} ${res.body}');
        return {'journeys': [], 'earlierRef': null, 'laterRef': null};
      }

    final data = jsonDecode(res.body);
    final List itineraries = data['itineraries'] ?? [];

    if (itineraries.isNotEmpty) {
    final firstLeg = (itineraries.first['legs'] as List).first;
      print('=== RAW LEG DEBUG ===');
      print('startTime: ${firstLeg['startTime']} (${firstLeg['startTime'].runtimeType})');
      print('endTime: ${firstLeg['endTime']} (${firstLeg['endTime'].runtimeType})');
      print('agencyTimeZoneOffset: ${firstLeg['agencyTimeZoneOffset']}');
      print('Full first leg keys: ${firstLeg.keys.toList()}');
      print('Full first leg: $firstLeg');
    }

    final journeys = itineraries.map<Map<String, dynamic>?>((it) {
      final legs = (it['legs'] as List)
          .where((l) => l['mode'] != 'WALK')
          .toList();

      if (legs.isEmpty) return null;

      final firstLeg = legs.first;
      final lastLeg  = legs.last;

      final depTz  = firstLeg['from']['tz'] as String? ?? 'UTC';
      final arrTz  = lastLeg['to']['tz']   as String? ?? 'UTC';

    final trainNames = legs
        .where((l) => l['displayName'] != null || l['routeShortName'] != null)
        .map((l) => (l['displayName'] ?? l['routeShortName']).toString())
        .join(' + ');

      return {
        'departure':   _utcIsoToLocalIso(firstLeg['startTime'], depTz),
        'arrival':     _utcIsoToLocalIso(lastLeg['endTime'],    arrTz),
        'duration': it['duration'] as int,
        'origin':      firstLeg['from']['name'],
        'destination': lastLeg['to']['name'],
        'trainName':   trainNames,
        'changes':     (it['transfers'] ?? 0) as int,
        'finalDestination': firstLeg['tripTo']?['name'],
      };
    })
    .whereType<Map<String, dynamic>>()
    .toList();

    return {
      'journeys':   journeys,
      'earlierRef': data['previousPageCursor'],
      'laterRef':   data['nextPageCursor'],
    };
  }

  /// Returns {lat, lng} for a city name, or null if not found.
  static Future<Map<String, double>?> geocodeCity(String name) async {
    final uri = Uri.parse('$_base/geocode')
        .replace(queryParameters: {'text': name});
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final List data = jsonDecode(res.body);
    // Prefer STOP type first, fall back to any result
    final hits = data.where((s) => s['lat'] != null && s['lon'] != null);
    if (hits.isEmpty) return null;
    final best = hits.first;
    return {'lat': (best['lat'] as num).toDouble(), 'lng': (best['lon'] as num).toDouble()};
  }

  static Future<Map<String, double>?> geocodeById(String stationId, String fallbackName) async {
    // Try by ID first
    final uri = Uri.parse('$_base/geocode')
        .replace(queryParameters: {'text': fallbackName});
    final res = await http.get(uri);
    if (res.statusCode != 200) return geocodeCity(fallbackName);

    final List data = jsonDecode(res.body);
    // Match by ID if possible
    final match = data.where((s) => s['id'].toString() == stationId && s['lat'] != null).firstOrNull;
    if (match != null) {
      return {'lat': (match['lat'] as num).toDouble(), 'lng': (match['lon'] as num).toDouble()};
    }
    // Fall back to name search
    return geocodeCity(fallbackName);
  }
}


String _utcIsoToLocalIso(String utcIso, String ianaTimezone) {
  // Ensure timezone data is initialised (safe to call multiple times)
  tz_data.initializeTimeZones();

  final location = tz.getLocation(ianaTimezone);
  final utcTime = DateTime.parse(utcIso).toUtc();
  final local = tz.TZDateTime.from(utcTime, location);

  // Return as ISO string — _fmt and _toTimeOfDay split on 'T' and take HH:mm
  return local.toIso8601String();
}