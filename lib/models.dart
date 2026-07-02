import 'package:flutter/material.dart';

class Trip {
  String name;
  List<Destination> destinations;
  Trip({required this.name, required this.destinations});

  Map<String, dynamic> toJson() => {
        'name': name,
        'destinations': destinations.map((d) => d.toJson()).toList(),
      };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        name: json['name'],
        destinations: (json['destinations'] as List).map((d) => Destination.fromJson(d)).toList(),
      );
}

class Destination {
  String name;
  Hotel? hotel;
  String extraInfo;
  List<Train>? trains;
  List<Flight>? flights;
  String? dates;
  double? lat;   // ← ADD
  double? lng;   // ← ADD

  Destination({required this.name, required this.hotel, required this.extraInfo,
      required this.trains, required this.flights, this.dates = '',
      this.lat, this.lng});  // ← ADD

  Map<String, dynamic> toJson() => {
        'name': name,
        'hotel': hotel?.toJson(),
        'extraInfo': extraInfo,
        'trains': trains?.map((t) => t.toJson()).toList(),
        'flights': flights?.map((f) => f.toJson()).toList(),
        'dates': dates,
        'lat': lat,   // ← ADD
        'lng': lng,   // ← ADD
      };

  factory Destination.fromJson(Map<String, dynamic> json) => Destination(
        name: json['name'],
        hotel: json['hotel'] != null ? Hotel.fromJson(json['hotel']) : null,
        extraInfo: json['extraInfo'],
        trains: json['trains'] != null
            ? (json['trains'] as List).map((t) => Train.fromJson(t)).toList()
            : null,
        flights: json['flights'] != null
            ? (json['flights'] as List).map((f) => Flight.fromJson(f)).toList()
            : null,
        dates: json['dates'],
        lat: (json['lat'] as num?)?.toDouble(),  // ← ADD
        lng: (json['lng'] as num?)?.toDouble(),  // ← ADD
      );
}

String getElapsedTimePlane(TimeOfDay departure, TimeOfDay arrival) {
  final now = DateTime.now();
  var dep = DateTime(now.year, now.month, now.day, departure.hour, departure.minute);
  var arr = DateTime(now.year, now.month, now.day, arrival.hour, arrival.minute);
  if (arr.isBefore(dep)) arr = arr.add(const Duration(days: 1));
  final diff = arr.difference(dep);
  return '${diff.inHours}h ${diff.inMinutes % 60}m';
}

String getElapsedTimeTrain(int? durationSeconds) {
  if (durationSeconds == null) return '';
  final hours = durationSeconds ~/ 3600;
  final minutes = (durationSeconds % 3600) ~/ 60;
  return '${hours}h ${minutes}m';
}

class Train {
  String start, end, startId, endId, finalDestination;
  String?  car, seats, trainName;
  String ? reservationPdfPath;
  TimeOfDay? departureTime, arrivalTime;
  int? duration;
  DateTime? date;

  Train({required this.start, required this.end, required this.startId, required this.endId, required this.departureTime,
      required this.arrivalTime, required this.finalDestination, this.car = '', this.seats = '', this.trainName = '', this.reservationPdfPath, this.duration, this.date});

  Map<String, dynamic> toJson() => {
        'start': start, 'end': end, 'startId' : startId, 'endId': endId,
        'departureTime': departureTime != null ? {'hour': departureTime!.hour, 'minute': departureTime!.minute} : null,
        'arrivalTime': arrivalTime != null ? {'hour': arrivalTime!.hour, 'minute': arrivalTime!.minute} : null,
        'finalDestination': finalDestination, 'car': car, 'seats': seats, 'trainName': trainName, 'reservationPdfPath': reservationPdfPath, 'duration': duration, 'date': date,
      };

  factory Train.fromJson(Map<String, dynamic> json) => Train(
        start: json['start'], end: json['end'], startId: json['startId'], endId: json['endId'],
        departureTime: json['departureTime'] != null
            ? TimeOfDay(hour: json['departureTime']['hour'], minute: json['departureTime']['minute'])
            : null,
        arrivalTime: json['arrivalTime'] != null
            ? TimeOfDay(hour: json['arrivalTime']['hour'], minute: json['arrivalTime']['minute'])
            : null,
        finalDestination: json['finalDestination'],
        reservationPdfPath: json['reservationPdfPath'],
        car: json['car'], seats: json['seats'], duration: json['duration'], date: json['date'],
      );
}

class Flight {
  String start, end, seats;
  TimeOfDay? departureTime, arrivalTime;

  Flight({required this.start, required this.end, required this.departureTime,
      required this.arrivalTime, this.seats = ''});

  Map<String, dynamic> toJson() => {
        'start': start, 'end': end,
        'departureTime': departureTime != null ? {'hour': departureTime!.hour, 'minute': departureTime!.minute} : null,
        'arrivalTime': arrivalTime != null ? {'hour': arrivalTime!.hour, 'minute': arrivalTime!.minute} : null,
        'seats': seats,
      };

  factory Flight.fromJson(Map<String, dynamic> json) => Flight(
        start: json['start'], end: json['end'],
        departureTime: json['departureTime'] != null
            ? TimeOfDay(hour: json['departureTime']['hour'], minute: json['departureTime']['minute'])
            : null,
        arrivalTime: json['arrivalTime'] != null
            ? TimeOfDay(hour: json['arrivalTime']['hour'], minute: json['arrivalTime']['minute'])
            : null,
        seats: json['seats'],
      );
}

class Hotel {
  String name, address, contactInfo, bookingReference, checkInDate, checkOutDate, price, link;

  Hotel({required this.name, required this.address, required this.contactInfo,
      required this.bookingReference, required this.checkInDate, required this.checkOutDate,
      required this.price, required this.link});

  Map<String, dynamic> toJson() => {
        'name': name, 'address': address, 'contactInfo': contactInfo,
        'bookingReference': bookingReference, 'checkInDate': checkInDate,
        'checkOutDate': checkOutDate, 'price': price, 'link': link,
      };

  factory Hotel.fromJson(Map<String, dynamic> json) => Hotel(
        name: json['name'], address: json['address'], contactInfo: json['contactInfo'],
        bookingReference: json['bookingReference'], checkInDate: json['checkInDate'],
        checkOutDate: json['checkOutDate'], price: json['price'], link: json['link'],
      );
}
