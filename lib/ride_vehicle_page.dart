import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ride_searching_page.dart';

class RideVehiclePage extends StatefulWidget {
  final String pickup;
  final String drop;

  const RideVehiclePage({
    super.key,
    required this.pickup,
    required this.drop,
  });

  @override
  State<RideVehiclePage> createState() => _RideVehiclePageState();
}

class _RideVehiclePageState extends State<RideVehiclePage> {
  String selectedVehicle = "Standard";

  int calculateFare(String type) {
    if (type == "Comfort") return 150;
    if (type == "Assist") return 180;
    return 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose your ride")),

      body: Column(
        children: [

          // 🚗 VEHICLE LIST
          Expanded(
            child: ListView(
              children: [
                vehicleTile("Standard", "Affordable ride", Icons.directions_car),
                vehicleTile("Comfort", "Low height, easy entry", Icons.airline_seat_recline_normal),
                vehicleTile("Assist", "Driver helps elderly", Icons.accessible),
              ],
            ),
          ),

          // ✅ CONFIRM BUTTON
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () async {

                String userId = FirebaseAuth.instance.currentUser!.uid;
                int fare = calculateFare(selectedVehicle);

                // 🔥 1️⃣ CREATE RIDE
                DocumentReference rideRef =
                    await FirebaseFirestore.instance.collection('rides').add({
                  "userId": userId,
                  "pickup": widget.pickup,
                  "drop": widget.drop,
                  "vehicle": selectedVehicle,
                  "fare": fare,
                  "status": "searching",
                  "driverId": null,
                  "paymentStatus": "unpaid", // ✅ IMPORTANT
                  "createdAt": Timestamp.now(),
                });

                // 🔥 2️⃣ CREATE PAYMENT (THIS WAS MISSING)
                await FirebaseFirestore.instance.collection('payments').add({
                  "rideId": rideRef.id,
                  "userId": userId,
                  "amount": fare,
                  "status": "pending",
                  "method": null,
                  "createdAt": Timestamp.now(),
                });

                // 🚀 GO TO SEARCHING PAGE
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RideSearchingPage(
                      rideId: rideRef.id,
                    ),
                  ),
                );
              },
              child: Text("Confirm ₹${calculateFare(selectedVehicle)}"),
            ),
          ),
        ],
      ),
    );
  }

  // 🚘 VEHICLE TILE UI
  Widget vehicleTile(String name, String desc, IconData icon) {
    bool isSelected = selectedVehicle == name;

    return ListTile(
      leading: Icon(icon),
      title: Text(name),
      subtitle: Text(desc),
      trailing: Text("₹${calculateFare(name)}"),
      tileColor: isSelected ? Colors.grey[300] : null,
      onTap: () {
        setState(() {
          selectedVehicle = name;
        });
      },
    );
  }
}