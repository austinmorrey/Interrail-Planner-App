import 'package:flutter/material.dart';
import 'constants.dart';
import 'models.dart';
import 'shared_widgets.dart';
import 'db_search.dart';
import 'dart:async';

class AddTripPage extends StatefulWidget {
  const AddTripPage({super.key});

  @override
  State<AddTripPage> createState() => _AddTripPageState();
}

class _AddTripPageState extends State<AddTripPage> {
  final nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Trip'),
        backgroundColor: kNavy,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trip name', style: TextStyle(fontWeight: FontWeight.w600, color: kSubtext, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'e.g. Summer Europe Trip'),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    Navigator.pop(context, Trip(
                      name: nameController.text,
                      destinations: [Destination(name: 'Start', hotel: null, extraInfo: '', trains: null, flights: null)],
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Create Trip', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddHotelPage extends StatefulWidget {
  final Hotel? existingHotel;
  const AddHotelPage({super.key, this.existingHotel});

  @override
  State<AddHotelPage> createState() => _AddHotelPageState();
}

class _AddHotelPageState extends State<AddHotelPage> {
  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController contactController;
  late TextEditingController bookingRefController;
  late TextEditingController checkInController;
  late TextEditingController checkOutController;
  late TextEditingController priceController;
  late TextEditingController linkController;

  @override
  void initState() {
    super.initState();
    nameController       = TextEditingController(text: widget.existingHotel?.name ?? '');
    addressController    = TextEditingController(text: widget.existingHotel?.address ?? '');
    contactController    = TextEditingController(text: widget.existingHotel?.contactInfo ?? '');
    bookingRefController = TextEditingController(text: widget.existingHotel?.bookingReference ?? '');
    checkInController    = TextEditingController(text: widget.existingHotel?.checkInDate ?? '');
    checkOutController   = TextEditingController(text: widget.existingHotel?.checkOutDate ?? '');
    priceController      = TextEditingController(text: widget.existingHotel?.price ?? '');
    linkController       = TextEditingController(text: widget.existingHotel?.link ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Accommodation'),
        backgroundColor: kNavy,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CustomField(controller: nameController,       label: 'Hotel name'),
            CustomField(controller: addressController,    label: 'Address'),
            CustomField(controller: contactController,    label: 'Contact'),
            CustomField(controller: bookingRefController, label: 'Booking reference'),
            CustomField(controller: checkInController,    label: 'Check-in date'),
            CustomField(controller: checkOutController,   label: 'Check-out date'),
            CustomField(controller: priceController,      label: 'Price'),
            CustomField(controller: linkController,       label: 'Link'),
            const SizedBox(height: 28),
            SaveButton(
              onPressed: () => Navigator.pop(context, Hotel(
                name: nameController.text,
                address: addressController.text,
                contactInfo: contactController.text,
                bookingReference: bookingRefController.text,
                checkInDate: checkInController.text,
                checkOutDate: checkOutController.text,
                price: priceController.text,
                link: linkController.text,
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class AddTrainPage extends StatefulWidget {
  final Train? existingTrain;
  const AddTrainPage({super.key, this.existingTrain});

  @override
  State<AddTrainPage> createState() => _AddTrainPageState();
}

class _AddTrainPageState extends State<AddTrainPage> {
  // Station selection
  Map<String, String>? _fromStation;   // {id, name}
  Map<String, String>? _toStation;

  // Journey selection
  Map<String, dynamic>? _selectedJourney;
  List<Map<String, dynamic>> _journeys = [];
  bool _loadingJourneys = false;

  // Optional extras
  final _carController  = TextEditingController();
  final _seatController = TextEditingController();
  final _finalDestController = TextEditingController();

  DateTime _travelDate = DateTime.now();
  // Add these alongside your existing state variables
  TimeOfDay? _departureTime;
  String? _earlierRef;
  String? _laterRef;
  bool _loadingEarlier = false;
  bool _loadingLater   = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingTrain != null) {
      final t = widget.existingTrain!;
      _fromStation = {'id': t.startId, 'name': t.start};
      _toStation   = {'id': t.endId,   'name': t.end};
      _travelDate  = t.date ?? DateTime.now();
      _departureTime = t.departureTime;
      _carController.text  = t.car ?? '';
      _seatController.text = t.seats ?? '';
      _finalDestController.text = t.finalDestination;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _travelDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final now = DateTime.now();
      setState(() => _travelDate = DateTime(
        picked.year, picked.month, picked.day,
        now.hour, now.minute,
      ));
      if (_fromStation != null && _toStation != null) _fetchJourneys();
    }
  }

  Future<void> _fetchJourneys({
  Map<String, String>? from,
  Map<String, String>? to,
  String? earlierRef,
  String? laterRef,
  }) async {
    final fromStation = from ?? _fromStation;
    final toStation   = to   ?? _toStation;
    if (fromStation == null || toStation == null) return;

    // Build the departure DateTime from date + time picker
    DateTime? when;
    if (_departureTime != null) {
      when = DateTime(
        _travelDate.year, _travelDate.month, _travelDate.day,
        _departureTime!.hour, _departureTime!.minute,
      );
    } else {
      when = DateTime(
        _travelDate.year, _travelDate.month, _travelDate.day,
        DateTime.now().hour, DateTime.now().minute,
      );
    }

    if (earlierRef != null) {
      setState(() => _loadingEarlier = true);
    } else if (laterRef != null) {
      setState(() => _loadingLater = true);
    } else {
      setState(() { _loadingJourneys = true; _journeys = []; _selectedJourney = null; });
    }

    final result = await TrainApiService.searchJourneys(
      fromId:     fromStation['id']!,
      toId:       toStation['id']!,
      when:       when,
      earlierRef: earlierRef,
      laterRef:   laterRef,
    );

    if (!mounted) return;

    setState(() {
      if (earlierRef != null) {
        _journeys = [...result['journeys'], ..._journeys];
        _loadingEarlier = false;
      } else if (laterRef != null) {
        _journeys = [..._journeys, ...result['journeys']];
        _loadingLater = false;
      } else {
        _journeys = result['journeys'];
        _loadingJourneys = false;
      }
      _earlierRef = result['earlierRef'];
      _laterRef   = result['laterRef'];
    });
  }

  bool get _isComplete =>
      _fromStation != null &&
      _toStation != null &&
      _selectedJourney != null;

  TimeOfDay _toTimeOfDay(String iso) {
    try {
      final timePart = iso.split('T')[1];
      return TimeOfDay(
        hour:   int.parse(timePart.substring(0, 2)),
        minute: int.parse(timePart.substring(3, 5)),
      );
    } catch (_) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTrain != null ? 'Edit Train' : 'Add Train'),
        backgroundColor: kNavy,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Station search fields ──
            StationSearchField(
              label: 'Departure station',
              selected: _fromStation,
              onSelected: (station) {
                setState(() { _fromStation = station; _journeys = []; });
                if (_toStation != null) _fetchJourneys(from: station, to: _toStation!);
              },
            ),
            const SizedBox(height: 12),
            StationSearchField(
              label: 'Arrival station',
              selected: _toStation,
              onSelected: (station) {
                setState(() { _toStation = station; _journeys = []; });
                if (_fromStation != null) _fetchJourneys(from: _fromStation!, to: station);
              },
            ),
            const SizedBox(height: 12),

            // ── Date picker ──
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: kDivider),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today, size: 16, color: kSubtext),
                  const SizedBox(width: 8),
                  Text(
                    '${_travelDate.day}/${_travelDate.month}/${_travelDate.year}',
                    style: const TextStyle(fontSize: 14, color: kText),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // ── Departure time picker ──
            GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _departureTime ?? TimeOfDay.now(),
                );
                if (picked != null) {
                  setState(() => _departureTime = picked);
                  if (_fromStation != null && _toStation != null) _fetchJourneys();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: kDivider),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.access_time, size: 16, color: kSubtext),
                  const SizedBox(width: 8),
                  Text(
                    _departureTime != null
                        ? _departureTime!.format(context)
                        : 'Departure time (optional)',
                    style: TextStyle(
                      fontSize: 14,
                      color: _departureTime != null ? kText : kSubtext,
                    ),
                  ),
                  const Spacer(),
                  if (_departureTime != null)
                    GestureDetector(
                      onTap: () {
                        setState(() => _departureTime = null);
                        if (_fromStation != null && _toStation != null) _fetchJourneys();
                      },
                      child: const Icon(Icons.close, size: 16, color: kSubtext),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // ── Journey results ──
            if (_fromStation != null && _toStation != null) ...[
              const Text('Select a train',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kSubtext)),
              const SizedBox(height: 8),
              if (_loadingJourneys)
                const Center(child: CircularProgressIndicator())
              else if (_journeys.isEmpty)
                const Text('No journeys found', style: TextStyle(color: kSubtext))
              else ...[
                // Earlier button
                _PaginationButton(
                  label: '<- Earlier',
                  loading: _loadingEarlier,
                  onTap: _earlierRef == null ? null : () => _fetchJourneys(earlierRef: _earlierRef),
                ),
                const SizedBox(height: 4),
                ..._journeys.map((j) => _JourneyOption(
                  journey: j,
                  selected: j == _selectedJourney,
                  onTap: () => setState(() => _selectedJourney = j),
                )),
                const SizedBox(height: 4),
                // Later button
                _PaginationButton(
                  label: 'Later ->',
                  loading: _loadingLater,
                  onTap: _laterRef == null ? null : () => _fetchJourneys(laterRef: _laterRef),
                ),
              ],
            ],

            // ── Optional seat reservation ──
            const Text('Seat reservation (optional)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kSubtext)),
            const SizedBox(height: 8),
            CustomField(controller: _carController,  label: 'Carriage number', onChanged: (_) => setState(() {})),
            CustomField(controller: _seatController, label: 'Seat numbers',    onChanged: (_) => setState(() {})),

            const SizedBox(height: 32),
            SaveButton(
              label: 'Save Train',
              enabled: _isComplete,
              onPressed: () {
                final j = _selectedJourney!;
                Navigator.pop(context, Train(
                  start:            j['origin'],
                  end:              j['destination'],
                  duration:         j['duration'] as int?,
                  date:             _travelDate,
                  startId:          _fromStation!['id']!,
                  endId:            _toStation!['id']!,
                  finalDestination: j['finalDestination'],
                  departureTime:    _toTimeOfDay(j['departure']),
                  arrivalTime:      _toTimeOfDay(j['arrival']),
                  trainName:        j['trainName'],
                  car:              _carController.text.isEmpty  ? null : _carController.text,
                  seats:            _seatController.text.isEmpty ? null : _seatController.text,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}


class StationSearchField extends StatefulWidget {
  final String label;
  final Map<String, String>? selected;
  final ValueChanged<Map<String, String>> onSelected;

  const StationSearchField({required this.label, required this.onSelected, this.selected, super.key});

  @override
  State<StationSearchField> createState() => _StationSearchFieldState();
}

class _StationSearchFieldState extends State<StationSearchField> {
  final _controller = TextEditingController();
  List<Map<String, String>> _suggestions = [];
  Timer? _debounce;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.selected != null) _controller.text = widget.selected!['name']!;
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.length < 2) { setState(() => _suggestions = []); return; }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _loading = true);
      final results = await TrainApiService.searchStations(value);
      setState(() { _suggestions = results; _loading = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.label,
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onChanged: _onChanged,
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kDivider),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
            ),
            child: Column(
              children: _suggestions.map((s) => ListTile(
                dense: true,
                leading: const Icon(Icons.train, size: 18, color: kSubtext),
                title: Text(s['name']!, style: const TextStyle(fontSize: 14)),
                onTap: () {
                  _controller.text = s['name']!;
                  setState(() => _suggestions = []);
                  widget.onSelected(s);
                },
              )).toList(),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() { _debounce?.cancel(); _controller.dispose(); super.dispose(); }
}

class _JourneyOption extends StatelessWidget {
  final Map<String, dynamic> journey;
  final bool selected;
  final VoidCallback onTap;

  const _JourneyOption({required this.journey, required this.selected, required this.onTap});

  String _fmt(String iso) {
    try {
      return iso.split('T')[1].substring(0, 5);
    } catch (_) {
      return '--:--';
    }
  }

  @override
  Widget build(BuildContext context) {
    final changes = journey['changes'] as int;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? kNavy : kLightBlue,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? kNavy : kDivider),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                '${_fmt(journey['departure'])}  ->  ${_fmt(journey['arrival'])}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: selected ? Colors.white : kText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                journey['trainName'] ?? '',
                style: TextStyle(fontSize: 12, color: selected ? Colors.white70 : kSubtext),
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? Colors.white24 : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              changes == 0 ? 'Direct' : '$changes change${changes > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 11,
                color: selected ? Colors.white : kSubtext,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  const _PaginationButton({required this.label, required this.loading, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: kLightBlue,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kDivider),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: onTap != null ? kNavy : kSubtext,
                  ),
                ),
        ),
      ),
    );
  }
}

class AddFlightPage extends StatefulWidget {
  final Flight? existingFlight;
  const AddFlightPage({super.key, this.existingFlight});

  @override
  State<AddFlightPage> createState() => _AddFlightPageState();
}

class _AddFlightPageState extends State<AddFlightPage> {
  late TextEditingController startController;
  late TextEditingController endController;
  late TextEditingController seatsController;
  TimeOfDay? departureTime;
  TimeOfDay? arrivalTime;

  @override
  void initState() {
    super.initState();
    startController  = TextEditingController(text: widget.existingFlight?.start ?? '');
    endController    = TextEditingController(text: widget.existingFlight?.end ?? '');
    seatsController  = TextEditingController(text: widget.existingFlight?.seats ?? '');
    departureTime    = widget.existingFlight?.departureTime;
    arrivalTime      = widget.existingFlight?.arrivalTime;
  }

  bool get _isComplete =>
      startController.text.isNotEmpty && endController.text.isNotEmpty &&
      departureTime != null && arrivalTime != null;

  Future<void> _pickTime(bool isDeparture) async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => isDeparture ? departureTime = picked : arrivalTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingFlight != null ? 'Edit Flight' : 'Add Flight'),
        backgroundColor: kNavy,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomField(controller: startController, label: 'Departure airport', onChanged: (_) => setState(() {})),
            CustomField(controller: endController, label: 'Arrival airport', onChanged: (_) => setState(() {})),
            CustomField(controller: seatsController, label: 'Seat numbers'),
            const SizedBox(height: 8),
            CustomTimePicker(label: 'Departure time', time: departureTime, onTap: () => _pickTime(true), context: context),
            CustomTimePicker(label: 'Arrival time', time: arrivalTime, onTap: () => _pickTime(false), context: context),
            const SizedBox(height: 32),
            SaveButton(
              label: 'Save Flight',
              enabled: _isComplete,
              onPressed: () => Navigator.pop(context, Flight(
                start: startController.text,
                end: endController.text,
                departureTime: departureTime,
                arrivalTime: arrivalTime,
                seats: seatsController.text,
              )),
            ),
          ],
        ),
      ),
    );
  }
}
