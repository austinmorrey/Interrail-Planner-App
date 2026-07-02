# Interrail Planner

A Flutter app for planning interrail and holiday trips — manage destinations, accommodation, train journeys, and flights all in one place, with a visual timeline and interactive map.

## Features

- **Trip timeline** — Add, reorder, and edit destinations along a visual vertical timeline.
- **Accommodation tracking** — Store hotel details, booking references, check-in/out dates, pricing, and booking links per destination.
- **Train journeys** — Search real train routes and timetables via the [Transitous](https://transitous.org/) API, with station autocomplete, journey pagination (earlier/later results), and automatic timezone handling.
- **Seat reservations** — Attach, view, and remove PDF reservation documents per train, stored locally on-device.
- **Flights** — Add flights with departure/arrival airports, times, and seat info.
- **Map view** — Visualize the full route (train stations and flight legs) on an OpenStreetMap-powered map, no API key required.
- **Import/export** — Share a trip as a JSON file or import one from disk.
- **Local persistence** — Trips are saved to the device automatically when the app is backgrounded.

## Tech Stack

- **Framework:** Flutter (Dart)
- **Map:** [`flutter_map`](https://pub.dev/packages/flutter_map) + OpenStreetMap tiles
- **Train data:** [Transitous API](https://api.transitous.org/api/v1) for station search and journey planning
- **Timezones:** [`timezone`](https://pub.dev/packages/timezone) package with IANA timezone data
- **File handling:** `file_picker`, `path_provider`, `open_filex` for PDF reservation uploads
- **Sharing:** `share_plus` for trip export

## Getting Started

### Prerequisites

- Flutter SDK (see `pubspec.yaml` for the required Dart SDK constraint)
- Android SDK configured for Android builds (`flutter doctor` to check status)

### Setup

```bash
git clone https://github.com/austinmorrey/Interrail-Planner-App.git
cd interrail-planner
flutter pub get
flutter run
```

> **Note:** If working on Windows, keep the project path free of spaces (e.g. `C:\FlutterApps\InterrailPlanner\`) to avoid Flutter tooling permission issues.

## Project Structure

```
lib/
├── main.dart              # App entry point
├── home_page.dart          # Trip list, import/save
├── trip_detail_page.dart   # Timeline view, destination/train/flight panels
├── add_forms.dart          # Forms for adding hotels, trains, flights
├── map_page.dart            # Route map view
├── db_search.dart           # Transitous API integration
├── storage.dart             # Local save/load/share logic
├── models.dart              # Trip, Destination, Hotel, Train, Flight models
├── shared_widgets.dart      # Reusable UI components
└── constants.dart           # Color palette and shared constants
```

## Roadmap

- [ ] Refine timeline connector line behavior
- [ ] Additional trip statistics / summary view