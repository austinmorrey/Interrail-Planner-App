import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'models.dart';

Future<void> shareTrip(Trip trip) async {
  final json = jsonEncode(trip.toJson());
  final directory = await getTemporaryDirectory();
  final path = '${directory.path}/${trip.name}.json';
  await File(path).writeAsString(json);
  await Share.shareXFiles([XFile(path)]);
}

Future<void> saveTrips(List<Trip> trips) async {
  final json = jsonEncode(trips.map((t) => t.toJson()).toList());
  final directory = await getApplicationDocumentsDirectory();
  final path = '${directory.path}/trips.json';
  await File(path).writeAsString(json);
}

Future<List<Trip>> loadTrips() async {
  final directory = await getApplicationDocumentsDirectory();
  final path = '${directory.path}/trips.json';
  final file = File(path);
  if (await file.exists()) {
    final json = await file.readAsString();
    final list = jsonDecode(json) as List;
    return list.map((t) => Trip.fromJson(t)).toList();
  }
  return [];
}
