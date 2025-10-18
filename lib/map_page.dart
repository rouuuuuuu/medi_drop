import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng? currentLocation;
  List<Marker> _pharmacyMarkers = [];
  List<Pharmacy> _sortedPharmacies = [];
  MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initLocationAndFetch();
  }

  // Step 1: Initialize location and fetch nearby pharmacies
  Future<void> _initLocationAndFetch() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
    });

    // Step 2: Fetch pharmacies after getting current location
    _fetchNearbyPharmacies(position.latitude, position.longitude);
  }

  // Step 2: Fetch nearby pharmacies from Overpass API
  Future<void> _fetchNearbyPharmacies(double lat, double lng) async {
    final radius = 10000; // radius in meters (10km radius)

    final overpassUrl = Uri.parse(
        'https://overpass-api.de/api/interpreter?data=[out:json];'
            'node(around:$radius,$lat,$lng)[amenity=pharmacy];out;'
    );

    final response = await http.get(overpassUrl);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      List<Pharmacy> pharmacies = [];
      List<Marker> newMarkers = [];

      setState(() {
        // Clear old markers before adding new ones
        _pharmacyMarkers = [];

        // Loop through each pharmacy and calculate distances
        for (var element in data['elements']) {
          final markerLat = element['lat'];
          final markerLon = element['lon'];
          final name = element['tags']['name'] ?? 'Unnamed Pharmacy';
          final openingHours = element['tags']['opening_hours'] ?? 'Unknown';

          // Calculate distance between current location and pharmacy
          final distance = Geolocator.distanceBetween(lat, lng, markerLat, markerLon);

          // Add the pharmacy to the list
          pharmacies.add(Pharmacy(
            name: name,
            latitude: markerLat,
            longitude: markerLon,
            distance: distance,
            openingHours: openingHours,
          ));

          // Add the marker for the pharmacy
          newMarkers.add(Marker(
            point: LatLng(markerLat, markerLon),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                _showPharmacyDetails(context, name, openingHours);
              },
              child: Icon(
                Icons.local_pharmacy,
                color: Colors.red,
                size: 30,
              ),
            ),
          ));
        }

        // Step 3: Sort pharmacies by distance
        pharmacies.sort((a, b) => a.distance.compareTo(b.distance));

        // Step 4: Set the top 3 closest pharmacies
        _sortedPharmacies = pharmacies.take(3).toList();

        // Update the pharmacy markers
        _pharmacyMarkers = newMarkers;

        // Step 5: Update the map bounds to include the user's location and pharmacies
        _updateMapBounds();
      });
    } else {
      print('Failed to load pharmacies: ${response.statusCode}');
    }
  }

  // Step 3: Show pharmacy details when a marker is tapped
  void _showPharmacyDetails(BuildContext context, String name, String openingHours) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(name),
          content: Text('Opening Hours: $openingHours'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Step 5: Update map bounds to include user location and pharmacies
  void _updateMapBounds() {
    if (currentLocation == null || _pharmacyMarkers.isEmpty) return;

    // Calculate the bounds for the map
    final latitudes = [
      ..._pharmacyMarkers.map((m) => m.point.latitude),
      currentLocation!.latitude,
    ];
    final longitudes = [
      ..._pharmacyMarkers.map((m) => m.point.longitude),
      currentLocation!.longitude,
    ];

    final minLat = latitudes.reduce((a, b) => a < b ? a : b);
    final maxLat = latitudes.reduce((a, b) => a > b ? a : b);
    final minLon = longitudes.reduce((a, b) => a < b ? a : b);
    final maxLon = longitudes.reduce((a, b) => a > b ? a : b);

    _mapController.move(
      LatLng((minLat + maxLat) / 2, (minLon + maxLon) / 2), // Center the map
      12, // Zoom level
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentLocation == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Nearby Pharmacies")),
      body: Column(
        children: [
          // Step 4: The map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: currentLocation,
                zoom: 15, // Default zoom level
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    // Marker for the user's current location
                    Marker(
                      point: currentLocation!,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.person_pin_circle,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                    // Markers for nearby pharmacies
                    ..._pharmacyMarkers,
                  ],
                ),
              ],
            ),
          ),
          // Step 5: Display list of top 3 nearest pharmacies
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Top 3 Nearest Pharmacies:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _sortedPharmacies.length,
              itemBuilder: (context, index) {
                final pharmacy = _sortedPharmacies[index];
                return ListTile(
                  title: Text(pharmacy.name),
                  subtitle: Text(
                    'Distance: ${pharmacy.distance.toStringAsFixed(2)} meters\nOpening Hours: ${pharmacy.openingHours}',
                  ),
                  onTap: () {
                    _showPharmacyDetails(context, pharmacy.name, pharmacy.openingHours);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Pharmacy {
  final String name;
  final double latitude;
  final double longitude;
  final double distance;
  final String openingHours;

  Pharmacy({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.openingHours,
  });
}
