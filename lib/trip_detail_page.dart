import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'constants.dart';
import 'models.dart';
import 'storage.dart';
import 'shared_widgets.dart';
import 'add_forms.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'map_page.dart';

class TripDetailPage extends StatefulWidget {
  final Trip trip;
  const TripDetailPage({super.key, required this.trip});

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  late List<Destination> destinations;
  int? openPanelIndex;
  int? openTrainIndex;
  int? openFlightIndex;

  @override
  void initState() {
    super.initState();
    destinations = widget.trip.destinations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FB),
      body: Column(
        children: [
          // ── Custom app bar ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kNavy, kAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.trip.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.map_outlined, color: Colors.white),
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => TripMapPage(trip: widget.trip))),
                    ),
                    IconButton(
                      icon: const Icon(Icons.ios_share_outlined, color: Colors.white),
                      onPressed: () => shareTrip(widget.trip),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Main content + bottom panel ──
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      openPanelIndex = null;
                      openTrainIndex = null;
                      openFlightIndex = null;
                    }),
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Timeline ──
                                  Column(
                                    children: [
                                      const SizedBox(height: 30),
                                      for (int i = 0; i < destinations.length; i++) ...[
                                        SizedBox(
                                          height: 97,
                                          child: Column(
                                            children: [
                                              Container(
                                                width: 14,
                                                height: 14,
                                                decoration: BoxDecoration(
                                                  color: kAccent,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white, width: 2),
                                                  boxShadow: [BoxShadow(color: kAccent.withValues(alpha: 0.3), blurRadius: 4)],
                                                ),
                                              ),
                                              if (i < destinations.length - 1)
                                                Expanded(
                                                  child: Container(
                                                    width: 2.5,
                                                    color: kDivider,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (i < destinations.length - 1)
                                          Container(width: 2.5, height: 13, color: kDivider),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(width: 14),
                                  // ── Cards ──
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        for (int i = 0; i < destinations.length; i++) ...[
                                          DestinationCard(
                                            destination: destinations[i].name,
                                            dates: destinations[i].dates,
                                            onDelete: () => setState(() {
                                              openPanelIndex = null;
                                              openFlightIndex = null;
                                              openTrainIndex = null;
                                              if (i > 0) {
                                                destinations[i - 1].trains = null;
                                                destinations[i - 1].flights = null;
                                              }
                                              destinations.removeAt(i);
                                            }),
                                            onEdit: (newName) => setState(() => destinations[i].name = newName),
                                            onInfo: () => setState(() {
                                              openPanelIndex = openPanelIndex == i ? null : i;
                                              openTrainIndex = null;
                                              openFlightIndex = null;
                                            }),
                                            onTap: () => setState(() {
                                              openPanelIndex = openPanelIndex == i ? null : i;
                                              openTrainIndex = null;
                                              openFlightIndex = null;
                                            }),
                                          ),
                                          if (i < destinations.length)
                                            TransportRow(
                                              index: i,
                                              destinations: destinations,
                                              openTrainIndex: openTrainIndex,
                                              openFlightIndex: openFlightIndex,
                                              onAddDestination: () => setState(() => destinations.insert(
                                                  i + 1,
                                                  Destination(name: "New Stop", hotel: null, extraInfo: "", trains: null, flights: null))),
                                              onTrainTap: () => setState(() {
                                                openTrainIndex = openTrainIndex == i ? null : i;
                                                openPanelIndex = null;
                                                openFlightIndex = null;
                                              }),
                                              onFlightTap: () => setState(() {
                                                openFlightIndex = openFlightIndex == i ? null : i;
                                                openPanelIndex = null;
                                                openTrainIndex = null;
                                              }),
                                            ),
                                        ],
                                        if (destinations.isEmpty)
                                          AddFirstStop(
                                            onAdd: () => setState(() => destinations.insert(
                                                0,
                                                Destination(name: "New Stop", hotel: null, extraInfo: "", trains: null, flights: null))),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Bottom info panel ──
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: openPanelIndex != null || openTrainIndex != null || openFlightIndex != null
                      ? MediaQuery.of(context).size.height * 0.5
                      : 0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(color: kNavy.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag handle
                      if (openPanelIndex != null || openTrainIndex != null || openFlightIndex != null)
                        const Padding(
                          padding: EdgeInsets.only(top: 10, bottom: 4),
                          child: SheetHandle(),
                        ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          child: openPanelIndex != null
                              ? DestinationPanel(
                                  destination: destinations[openPanelIndex!],
                                  onUpdate: () => setState(() {}),
                                  context: context,
                                  openPanelIndex: openPanelIndex!,
                                  onSet: (fn) => setState(fn),
                                )
                              : openTrainIndex != null
                                  ? TrainPanel(
                                      destinations: destinations,
                                      openTrainIndex: openTrainIndex!,
                                      onUpdate: () => setState(() {}),
                                      context: context,
                                      onSet: (fn) => setState(fn),
                                    )
                                  : openFlightIndex != null
                                      ? FlightPanel(
                                          destinations: destinations,
                                          openFlightIndex: openFlightIndex!,
                                          onUpdate: () => setState(() {}),
                                          context: context,
                                          onSet: (fn) => setState(fn),
                                        )
                                      : const SizedBox(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TransportRow extends StatelessWidget {
  final int index;
  final List<Destination> destinations;
  final int? openTrainIndex;
  final int? openFlightIndex;
  final VoidCallback onAddDestination;
  final VoidCallback onTrainTap;
  final VoidCallback onFlightTap;

  const TransportRow({
    required this.index,
    required this.destinations,
    required this.openTrainIndex,
    required this.openFlightIndex,
    required this.onAddDestination,
    required this.onTrainTap,
    required this.onFlightTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAddDestination,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_circle_outline, size: 16, color: kSubtext),
                const SizedBox(width: 4),
                const Text('Add stop', style: TextStyle(color: kSubtext, fontSize: 11)),
              ],
            ),
          ),
          const Spacer(),
          if (index < destinations.length - 1) ...[
            TransportButton(
              icon: Icons.flight_takeoff,
              active: openFlightIndex == index,
              onTap: onFlightTap,
            ),
            const SizedBox(width: 4),
            TransportButton(
              icon: Icons.train_outlined,
              active: openTrainIndex == index,
              onTap: onTrainTap,
            ),
          ],
        ],
      ),
    );
  }
}

class TransportButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const TransportButton({required this.icon, required this.active, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? kAccent : kLightBlue,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, size: 16, color: active ? Colors.white : kAccent),
      ),
    );
  }
}

class AddFirstStop extends StatelessWidget {
  final VoidCallback onAdd;
  const AddFirstStop({required this.onAdd, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onAdd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_location_alt_outlined, color: kBlue.withValues(alpha: 0.5), size: 40),
            const SizedBox(height: 8),
            const Text('Add your first stop', style: TextStyle(color: kSubtext)),
          ],
        ),
      ),
    );
  }
}

class DestinationPanel extends StatelessWidget {
  final Destination destination;
  final VoidCallback onUpdate;
  final BuildContext context;
  final int openPanelIndex;
  final void Function(VoidCallback) onSet;

  const DestinationPanel({
    required this.destination,
    required this.onUpdate,
    required this.context,
    required this.openPanelIndex,
    required this.onSet,
    super.key,
  });

  @override
  Widget build(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(destination.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kText)),
        const SizedBox(height: 14),
        InfoCard(
          title: 'Accommodation',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconBtn(icon: Icons.delete_outline, onTap: () => onSet(() => destination.hotel = null)),
              IconBtn(
                icon: Icons.edit_outlined,
                onTap: () async {
                  final hotel = await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => AddHotelPage(existingHotel: destination.hotel)));
                  if (hotel != null) onSet(() => destination.hotel = hotel);
                },
              ),
            ],
          ),
          child: destination.hotel != null
              ? HotelDetails(hotel: destination.hotel!)
              : const EmptyLabel('No accommodation added yet'),
        ),
        const SizedBox(height: 10),
        InfoCard(
          title: 'Extra Information',
          trailing: IconBtn(
            icon: Icons.edit_outlined,
            onTap: () {
              final controller = TextEditingController(text: destination.extraInfo);
              showDialog(
                context: context,
                builder: (_) => EditDialog(
                  title: 'Extra Information',
                  onSave: () => onSet(() => destination.extraInfo = controller.text),
                  child: TextField(controller: controller, maxLines: 5,
                      decoration: const InputDecoration(hintText: 'Enter extra information...')),
                ),
              );
            },
          ),
          child: destination.extraInfo.isEmpty
              ? const EmptyLabel('No extra information added yet')
              : Text(destination.extraInfo, style: const TextStyle(color: kText)),
        ),
        const SizedBox(height: 10),
        InfoCard(
          title: 'Dates',
          trailing: IconBtn(
            icon: Icons.edit_outlined,
            onTap: () {
              final controller = TextEditingController(text: destination.dates);
              showDialog(
                context: context,
                builder: (_) => EditDialog(
                  title: 'Dates',
                  onSave: () => onSet(() => destination.dates = controller.text.trimRight()),
                  child: TextField(controller: controller,
                      decoration: const InputDecoration(hintText: 'e.g. 12 Jun - 15 Jun')),
                ),
              );
            },
          ),
          child: (destination.dates == null || destination.dates!.isEmpty)
              ? const EmptyLabel('No dates added yet')
              : Text(destination.dates!, style: const TextStyle(color: kText)),
        ),
      ],
    );
  }
}

class HotelDetails extends StatelessWidget {
  final Hotel hotel;
  const HotelDetails({required this.hotel, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailRow(label: 'Hotel', value: hotel.name),
        DetailRow(label: 'Address', value: hotel.address),
        DetailRow(label: 'Contact', value: hotel.contactInfo),
        DetailRow(label: 'Booking Ref', value: hotel.bookingReference),
        DetailRow(label: 'Check-in', value: hotel.checkInDate),
        DetailRow(label: 'Check-out', value: hotel.checkOutDate),
        DetailRow(label: 'Price', value: hotel.price),
        GestureDetector(
          onTap: () async {
            final uri = Uri.parse(hotel.link);
            if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
          },
          child: RichText(
            text: TextSpan(children: [
              const TextSpan(text: 'Link: ', style: TextStyle(color: kSubtext, fontSize: 13)),
              TextSpan(
                text: hotel.link,
                style: const TextStyle(color: kAccent, fontSize: 13, decoration: TextDecoration.underline),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const DetailRow({required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(text: '$label: ', style: const TextStyle(color: kSubtext, fontSize: 13)),
          TextSpan(text: value, style: const TextStyle(color: kText, fontSize: 13)),
        ]),
      ),
    );
  }
}

class TrainPanel extends StatelessWidget {
  final List<Destination> destinations;
  final int openTrainIndex;
  final VoidCallback onUpdate;
  final BuildContext context;
  final void Function(VoidCallback) onSet;

  const TrainPanel({
    required this.destinations,
    required this.openTrainIndex,
    required this.onUpdate,
    required this.context,
    required this.onSet,
    super.key,
  });

  @override
  Widget build(BuildContext ctx) {
    final dep = destinations[openTrainIndex];
    final arr = destinations[openTrainIndex + 1];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.train, size: 18, color: kAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${dep.name} → ${arr.name}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kText)),
          ),
        ]),
        if (dep.dates != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('Departing ${dep.dates!.length >= 6 ? dep.dates!.substring(dep.dates!.length - 6) : dep.dates!}',
                style: const TextStyle(fontSize: 12, color: kSubtext)),
          ),
        const SizedBox(height: 14),
        if (dep.trains == null || dep.trains!.isEmpty)
          const EmptyLabel('No trains added yet')
        else
          for (final train in dep.trains!)
            TrainCard(
              train: train,
              onEdit: () async {
                final updated = await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => AddTrainPage(existingTrain: train)));
                if (updated != null) {
                  onSet(() {
                    final idx = dep.trains!.indexOf(train);
                    dep.trains![idx] = updated;
                  });
                }
              },
              onDelete: () => onSet(() => dep.trains!.remove(train)),
              context: context,
            ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final train = await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddTrainPage()));
            if (train != null) {
              onSet(() {
                dep.trains ??= [];
                dep.trains!.add(train);
              });
            }
          },
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_circle_outline, size: 16, color: kAccent),
            SizedBox(width: 6),
            Text('Add train', style: TextStyle(color: kAccent, fontWeight: FontWeight.w600)),
          ]),
        ),
      ],
    );
  }
}

class TrainCard extends StatelessWidget {
  final Train train;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final BuildContext context;

  const TrainCard({required this.train, required this.onEdit, required this.onDelete, required this.context, super.key});

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onLongPress: () => showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => TrainBottomSheet(train: train, onEdit: onEdit, onDelete: onDelete, context: context),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kLightBlue,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kDivider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarqueeTextWidget(
                        text: '${train.start} → ${train.end}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kText),
                        maxWidth: 220,
                      ),
                      if (train.trainName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          train.trainName!,
                          style: const TextStyle(fontSize: 11, color: kSubtext),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    const Icon(Icons.access_time, size: 12, color: kSubtext),
                    const SizedBox(width: 4),
                    Text(getElapsedTimeTrain(train.duration),
                        style: const TextStyle(color: kSubtext, fontSize: 11)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${train.departureTime?.format(ctx) ?? '?'}  ->  ${train.arrivalTime?.format(ctx) ?? '?'}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kAccent),
                ),
                const Spacer(),
                MarqueeTextWidget(
                  text: 'Train For: ${train.finalDestination}',
                  style: const TextStyle(color: kSubtext, fontSize: 11),
                  maxWidth: 130,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TrainBottomSheet extends StatelessWidget {
  final Train train;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final BuildContext context;

  const TrainBottomSheet({required this.train, required this.onEdit, required this.onDelete, required this.context, super.key});

  @override
  Widget build(BuildContext ctx) {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),

            // ── Edit ──
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: kAccent),
              title: const Text('Edit train'),
              onTap: () { Navigator.pop(ctx); onEdit(); },
            ),

            // ── Seat reservations ──
            ListTile(
              leading: const Icon(Icons.chair_outlined, color: kAccent),
              title: const Text('Seat reservations'),
              onTap: () {
                Navigator.pop(ctx);
                final carController = TextEditingController(text: train.car);
                final seatsController = TextEditingController(text: train.seats);
                showDialog(
                  context: context,
                  builder: (_) => StatefulBuilder(
                    builder: (context, setDialogState) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Seat Reservations'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: carController,
                            decoration: const InputDecoration(labelText: 'Carriage'),
                            onChanged: (v) => train.car = v,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: seatsController,
                            decoration: const InputDecoration(labelText: 'Seats'),
                            onChanged: (v) => train.seats = v,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
                      ],
                    ),
                  ),
                );
              },
            ),

            // ── Upload reservation PDF ──
            ListTile(
              leading: const Icon(Icons.upload_file_outlined, color: kAccent),
              title: const Text('Upload reservation PDF'),
              onTap: () async {
                final result = await FilePicker.platform.pickFiles(
                  dialogTitle: 'Select reservation PDF',
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                );
                if (result == null) return;

                // Copy into app documents so it persists
                final srcPath = result.files.single.path!;
                final docsDir = await getApplicationDocumentsDirectory();
                final fileName = 'reservation_${DateTime.now().millisecondsSinceEpoch}.pdf';
                final destPath = '${docsDir.path}/$fileName';
                await File(srcPath).copy(destPath);

                train.reservationPdfPath = destPath;
                setSheetState(() {}); // refresh sheet to show new tiles
              },
            ),

            // ── View PDF (only when one is attached) ──
            if (train.reservationPdfPath != null) ...[
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined, color: kAccent),
                title: const Text('View reservation PDF'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await OpenFilex.open(train.reservationPdfPath!);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.orange),
                title: const Text('Remove PDF', style: TextStyle(color: Colors.orange)),
                onTap: () {
                  train.reservationPdfPath = null;
                  setSheetState(() {});
                },
              ),
            ],

            // ── Delete train ──
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete train', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Delete train'),
                    content: const Text('Are you sure you want to delete this train?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          if (train.reservationPdfPath != null) {
                            final file = File(train.reservationPdfPath!);
                            if (file.existsSync()) file.deleteSync();
                          }
                          Navigator.pop(dialogContext);
                          onDelete();
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class FlightPanel extends StatelessWidget {
  final List<Destination> destinations;
  final int openFlightIndex;
  final VoidCallback onUpdate;
  final BuildContext context;
  final void Function(VoidCallback) onSet;

  const FlightPanel({
    required this.destinations,
    required this.openFlightIndex,
    required this.onUpdate,
    required this.context,
    required this.onSet,
    super.key,
  });

  @override
  Widget build(BuildContext ctx) {
    final dep = destinations[openFlightIndex];
    final arr = destinations[openFlightIndex + 1];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.flight_takeoff, size: 18, color: kAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${dep.name} → ${arr.name}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kText)),
          ),
        ]),
        if (dep.dates != null && dep.dates!.contains('-'))
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('Departing ${dep.dates!.split('-').last.trim()}',
                style: const TextStyle(fontSize: 12, color: kSubtext)),
          ),
        const SizedBox(height: 14),
        if (dep.flights == null || dep.flights!.isEmpty)
          const EmptyLabel('No flights added yet')
        else
          for (final flight in dep.flights!)
            FlightCard(
              flight: flight,
              onEdit: () async {
                final updated = await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => AddFlightPage(existingFlight: flight)));
                if (updated != null) {
                  onSet(() {
                    final idx = dep.flights!.indexOf(flight);
                    dep.flights![idx] = updated;
                  });
                }
              },
              onDelete: () => onSet(() => dep.flights!.remove(flight)),
              context: context,
            ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final flight = await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddFlightPage()));
            if (flight != null) {
              onSet(() {
                dep.flights ??= [];
                dep.flights!.add(flight);
              });
            }
          },
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_circle_outline, size: 16, color: kAccent),
            SizedBox(width: 6),
            Text('Add flight', style: TextStyle(color: kAccent, fontWeight: FontWeight.w600)),
          ]),
        ),
      ],
    );
  }
}

class FlightCard extends StatelessWidget {
  final Flight flight;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final BuildContext context;

  const FlightCard({required this.flight, required this.onEdit, required this.onDelete, required this.context, super.key});

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onLongPress: () => showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: kAccent),
              title: const Text('Edit flight'),
              onTap: () { Navigator.pop(context); onEdit(); },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete flight', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Delete flight'),
                    content: const Text('Are you sure?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () { Navigator.pop(context); onDelete(); },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kLightBlue,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kDivider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: MarqueeTextWidget(
                    text: '${flight.start} → ${flight.end}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kText),
                    maxWidth: 220,
                  ),
                ),
                if (flight.departureTime != null && flight.arrivalTime != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      const Icon(Icons.schedule, size: 12, color: kSubtext),
                      const SizedBox(width: 4),
                      Text(getElapsedTimePlane(flight.departureTime!, flight.arrivalTime!),
                          style: const TextStyle(color: kSubtext, fontSize: 11)),
                    ]),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${flight.departureTime?.format(ctx) ?? '?'}  →  ${flight.arrivalTime?.format(ctx) ?? '?'}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kAccent),
            ),
          ],
        ),
      ),
    );
  }
}

class DestinationCard extends StatefulWidget {
  final String destination;
  final String? dates;
  final VoidCallback onDelete;
  final Function(String) onEdit;
  final VoidCallback onInfo;
  final VoidCallback onTap;

  const DestinationCard({
    super.key,
    required this.destination,
    this.dates,
    required this.onDelete,
    required this.onTap,
    required this.onEdit,
    required this.onInfo,
  });

  @override
  State<DestinationCard> createState() => _DestinationCardState();
}

class _DestinationCardState extends State<DestinationCard> {
  bool isEditing = false;
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.destination);
  }

  @override
  void didUpdateWidget(DestinationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.destination != widget.destination) controller.text = widget.destination;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 1,
      shadowColor: kNavy.withValues(alpha: 0.08),
      child: InkWell(
        onTap: isEditing ? null : widget.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: kLightBlue, borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.location_on_outlined, size: 22, color: kAccent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: isEditing
                    ? TextField(
                        controller: controller,
                        autofocus: true,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kText),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.destination,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kText)),
                          if (widget.dates != null && widget.dates!.isNotEmpty)
                            Text(widget.dates!, style: const TextStyle(fontSize: 11, color: kSubtext)),
                        ],
                      ),
              ),
              const SizedBox(width: 8),
              IconBtn(
                icon: Icons.info_outline,
                color: kAccent,
                onTap: widget.onInfo,
              ),
              IconBtn(
                icon: isEditing ? Icons.check_circle_outline : Icons.edit_outlined,
                color: isEditing ? Colors.green : kSubtext,
                onTap: () {
                  if (isEditing) widget.onEdit(controller.text);
                  setState(() => isEditing = !isEditing);
                },
              ),
              IconBtn(
                icon: Icons.delete_outline,
                color: isEditing ? kDivider : kSubtext,
                onTap: isEditing ? null : widget.onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
