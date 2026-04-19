import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapPickerPage extends StatefulWidget {
  final String apiKey;
  const MapPickerPage({super.key, required this.apiKey});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  // Default to Lucknow center
  LatLng _selectedLoc = const LatLng(26.8467, 80.9462);
  final TextEditingController _searchController = TextEditingController();

  // 🔍 SEARCH LOGIC: Converts text to LatLng and moves the map
  Future<void> _searchAndMove(String text) async {
    if (text.isEmpty) return;
    final url = "https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(text)}&key=${widget.apiKey}";
    
    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final loc = data['results'][0]['geometry']['location'];
        setState(() {
          _selectedLoc = LatLng(loc['lat'], loc['lng']);
        });
      }
    } catch (e) {
      debugPrint("Search error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Search location...",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onSubmitted: _searchAndMove,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.greenAccent),
            onPressed: () => Navigator.pop(context, _selectedLoc),
          )
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: _selectedLoc, zoom: 14),
        onTap: (loc) => setState(() => _selectedLoc = loc),
        markers: {
          Marker(markerId: const MarkerId("picked"), position: _selectedLoc)
        },
      ),
    );
  }
}