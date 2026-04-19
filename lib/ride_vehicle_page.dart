import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ride_searching_page.dart';
import 'dart:math';

class RideVehiclePage extends StatefulWidget {
  final String pickup;
  final String drop;
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;

  const RideVehiclePage({
    super.key,
    required this.pickup,
    required this.drop,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropLat,
    required this.dropLng,
  });

  @override
  State<RideVehiclePage> createState() => _RideVehiclePageState();
}

class _RideVehiclePageState extends State<RideVehiclePage> {
  String selectedVehicle = "Standard";
  bool femaleOnly = false;
  double simulatedDistance = 0.0;

  final Map<String, Map<String, double>> vehicleRates = {
    "Standard": {"base": 40, "perKm": 12},
    "Comfort": {"base": 60, "perKm": 15},
    "Junior": {"base": 65, "perKm": 16}, // 🔥 New Baby Category
    "Assist": {"base": 70, "perKm": 18},
    "Wheelchair": {"base": 100, "perKm": 22},
    "Medical Plus": {"base": 90, "perKm": 20},
    "Senior XL": {"base": 80, "perKm": 19},
  };

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 + c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    double straightDistance = 12742 * asin(sqrt(a));
    return straightDistance * 1.25; 
  }

  int calculateDynamicFare(String type, double distance) {
    var rates = vehicleRates[type] ?? vehicleRates["Standard"]!;
    double fare = rates["base"]! + (distance * rates["perKm"]!);
    return (fare / 5).round() * 5;
  }

  @override
  void initState() {
    super.initState();
    simulatedDistance = _calculateDistance(
      widget.pickupLat,
      widget.pickupLng,
      widget.dropLat,
      widget.dropLng,
    );
  }

  @override
  Widget build(BuildContext context) {
    int currentFare = calculateDynamicFare(selectedVehicle, simulatedDistance);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Select Vehicle", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 🗺️ ROUTE SUMMARY HEADER
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
                ),
                child: Row(
                  children: [
                     Column(
                      children: [
                        Icon(Icons.radio_button_checked, color: Colors.green, size: 18),
                        Container(width: 2, height: 20, color: Colors.grey),
                        Icon(Icons.location_on, color: Colors.red, size: 18),
                      ],
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.pickup, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                          const Divider(height: 20),
                          Text(widget.drop, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 🚗 VEHICLE LIST
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const Text("Ride Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    _modernVehicleCard("Standard", "Swift and affordable", Icons.directions_car_rounded),
                    _modernVehicleCard("Comfort", "Spacious", Icons.airline_seat_recline_extra_rounded),
                    _modernVehicleCard("Junior", "Equipped with baby car seat", Icons.child_care_rounded), // 🔥 Added
                    _modernVehicleCard("Assist", "Driver assistance included", Icons.handshake_rounded),
                    _modernVehicleCard("Wheelchair", "Foldable ramp access", Icons.accessible_forward_rounded),
                    _modernVehicleCard("Medical Plus", "Emergency support", Icons.medical_services_rounded),
                    _modernVehicleCard("Senior XL", "High seating SUV", Icons.elderly_rounded),
                    
                    // 🔥 FIX: EXTRA PADDING AT BOTTOM TO PREVENT OVERLAP WITH FLOATING BUTTONS
                    const SizedBox(height: 220), 
                  ],
                ),
              ),
            ],
          ),

          // 💖 FEMALE ONLY FLOATING ANIMATION & TOGGLE
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: femaleOnly ? const Color(0xFFFFEBF2) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: femaleOnly ? Colors.pinkAccent : Colors.grey.shade200,
                  width: 2,
                ),
                boxShadow: femaleOnly 
                  ? [BoxShadow(color: Colors.pink.withOpacity(0.3), blurRadius: 15, spreadRadius: 2)]
                  : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  AnimatedScale(
                    scale: femaleOnly ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 500),
                    child: Icon(
                      femaleOnly ? Icons.female_rounded : Icons.person_search_rounded,
                      color: femaleOnly ? Colors.pink : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Female Only Driver", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("Priority for female captains", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: femaleOnly,
                    activeColor: Colors.pink,
                    onChanged: (val) => setState(() => femaleOnly = val),
                  ),
                ],
              ),
            ),
          ),

          // ⚡ BOTTOM CONFIRMATION BUTTON
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D3250),
                minimumSize: const Size(double.infinity, 65),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 8,
              ),
              onPressed: () async {
                String userId = FirebaseAuth.instance.currentUser!.uid;
                String randomOtp = (Random().nextInt(9000) + 1000).toString();

                DocumentReference rideRef = await FirebaseFirestore.instance.collection('rides').add({
                  "userId": userId,
                  "pickup": {"address": widget.pickup, "lat": widget.pickupLat, "lng": widget.pickupLng},
                  "drop": {"address": widget.drop, "lat": widget.dropLat, "lng": widget.dropLng},
                  "vehicle": selectedVehicle,
                  "fare": currentFare,
                  "distance": double.parse(simulatedDistance.toStringAsFixed(1)),
                  "status": "searching",
                  "driverId": null,
                  "paymentStatus": "unpaid",
                  "femaleOnly": femaleOnly,
                  "rejectedBy": [],
                  "otp": randomOtp,
                  "createdAt": Timestamp.now(),
                });

                await FirebaseFirestore.instance.collection('payments').add({
                  "rideId": rideRef.id,
                  "userId": userId,
                  "amount": currentFare,
                  "status": "pending",
                  "method": null,
                  "createdAt": Timestamp.now(),
                });

                if (!mounted) return;
                Navigator.push(context, MaterialPageRoute(builder: (_) => RideSearchingPage(rideId: rideRef.id)));
              },
              child: Text("Book $selectedVehicle • ₹$currentFare",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernVehicleCard(String name, String desc, IconData icon) {
    bool isSelected = selectedVehicle == name;
    int fare = calculateDynamicFare(name, simulatedDistance);

    return GestureDetector(
      onTap: () => setState(() => selectedVehicle = name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D3250) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected 
            ? [BoxShadow(color: const Color(0xFF2D3250).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
            : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : const Color(0xFFF1F4FF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: isSelected ? Colors.white : const Color(0xFF2D3250), size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? Colors.white : Colors.black)),
                  Text(desc, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white70 : Colors.grey)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("₹$fare", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isSelected ? Colors.white : Colors.black)),
                Text("${simulatedDistance.toStringAsFixed(1)} km", style: TextStyle(fontSize: 10, color: isSelected ? Colors.white60 : Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}