import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'constants.dart';
import 'models.dart';
import 'storage.dart';
import 'shared_widgets.dart';
import 'add_forms.dart';
import 'trip_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  List<Trip> trips = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialTrips();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      saveTrips(trips);
    }
  }

  Future<void> _loadInitialTrips() async {
    final loaded = await loadTrips();
    if (loaded.isNotEmpty) setState(() => trips = loaded);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FB),
      body: CustomScrollView(
        slivers: [
          // ── Gradient app bar ──
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: kNavy,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                'Holiday Planner',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  letterSpacing: -0.3,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kNavy, kAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.save_outlined, color: Colors.white),
                tooltip: 'Save',
                onPressed: () => saveTrips(trips),
              ),
              IconButton(
                icon: const Icon(Icons.folder_open_outlined, color: Colors.white),
                tooltip: 'Load',
                onPressed: () async {
                  final loaded = await loadTrips();
                  if (loaded.isNotEmpty) setState(() => trips = loaded);
                },
              ),
              const SizedBox(width: 4),
            ],
          ),

          // ── Empty state ──
          if (trips.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.luggage_outlined, size: 72, color: kBlue.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    const Text('No trips yet', style: TextStyle(fontSize: 18, color: kSubtext, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    const Text('Tap + to plan your first adventure', style: TextStyle(color: kSubtext, fontSize: 13)),
                  ],
                ),
              ),
            ),

          // ── Trip cards ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final trip = trips[i];
                  return TripCard(
                    trip: trip,
                    onDelete: () => setState(() => trips.remove(trip)),
                    onTap: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => TripDetailPage(trip: trip)));
                      setState(() {});
                    },
                    onEdit: (newName) => setState(() => trip.name = newName),
                  );
                },
                childCount: trips.length,
              ),
            ),
          ),
        ],
      ),

      // ── FABs ──
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'import',
            backgroundColor: Colors.white,
            foregroundColor: kAccent,
            elevation: 2,
            mini: true,
            tooltip: 'Import trip',
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(
                dialogTitle: 'Import trip',
                type: FileType.custom,
                allowedExtensions: ['json'],
              );
              if (result != null) {
                final file = File(result.files.single.path!);
                final json = await file.readAsString();
                final trip = Trip.fromJson(jsonDecode(json));
                setState(() => trips.add(trip));
              }
            },
            child: const Icon(Icons.file_open_outlined),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add',
            backgroundColor: kAccent,
            foregroundColor: Colors.white,
            elevation: 3,
            icon: const Icon(Icons.add),
            label: const Text('New Trip', style: TextStyle(fontWeight: FontWeight.w600)),
            onPressed: () async {
              final newTrip = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddTripPage()));
              if (newTrip != null) setState(() => trips.add(newTrip));
            },
          ),
        ],
      ),
    );
  }
}

class TripCard extends StatefulWidget {
  final Trip trip;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(String) onEdit;

  const TripCard({
    super.key,
    required this.trip,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<TripCard> {
  bool isEditing = false;
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.trip.name);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 1,
        shadowColor: kNavy.withValues(alpha: 0.08),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isEditing ? null : widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: kLightBlue,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.map_outlined, color: kAccent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      isEditing
                          ? TextField(
                              controller: controller,
                              autofocus: true,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kText),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                              ),
                            )
                          : Text(widget.trip.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
                      const SizedBox(height: 4),
                      MarqueeTextWidget(
                        text: widget.trip.destinations.map((d) => d.name).join('  ->  '),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kSubtext),
                        maxWidth: 100,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kLightBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.trip.destinations.length} stop${widget.trip.destinations.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 11, color: kAccent, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(isEditing ? Icons.check : Icons.edit_outlined, size: 20, color: kSubtext),
                  onPressed: () {
                    if (isEditing) widget.onEdit(controller.text);
                    setState(() => isEditing = !isEditing);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: kSubtext),
                  onPressed: isEditing ? null : widget.onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
