import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'driver_otp_page.dart';
import 'main.dart';

class DriverPickupPage extends StatefulWidget {
  final String rideId;

  const DriverPickupPage({super.key, required this.rideId});

  @override
  State<DriverPickupPage> createState() => _DriverPickupPageState();
}

class _DriverPickupPageState extends State<DriverPickupPage> {

  int remainingSeconds = 300; //  5 minutes
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds == 0) {
        t.cancel();
      } else {
        setState(() {
          remainingSeconds--;
        });
      }
    });
  }

  String formatTime(int seconds) {
    int min = seconds ~/ 60;
    int sec = seconds % 60;
    return "$min:${sec.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text("Pickup Location"),
        backgroundColor: Colors.black,
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .doc(widget.rideId)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var ride = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                // 📍 PICKUP CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        "Pickup Location",
                        style: TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        ride['pickup'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 18),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              "Drop: ${ride['drop']}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        ],
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Fare: ₹${ride['fare']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ⏱️ TIMER CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [

                      const Text(
                        "Reach within",
                        style: TextStyle(color: Colors.white70),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        formatTime(remainingSeconds),
                        style: const TextStyle(
                          fontSize: 30,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ⚙️ ACTION BUTTONS
                Row(
                  children: [

                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          // You can integrate maps later
                        },
                        icon: const Icon(Icons.navigation),
                        label: const Text("Navigate"),
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          // Call user simulation
                        },
                        icon: const Icon(Icons.call),
                        label: const Text("Call User"),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // ❌ CANCEL BUTTON
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
    onPressed: () async {
      try {
        await FirebaseFirestore.instance
            .collection('rides')
            .doc(widget.rideId)
            .update({
          "status": "cancelled",
        });

        if (!context.mounted) return;

        Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (_) => const DriverHome()),
  (route) => false,
);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Cancel failed: $e")),
        );
      }
    },
    child: const Text(
      "Cancel Ride",
      style: TextStyle(fontSize: 16),
    ),
  ),
),

                const Spacer(),

                // 🚀 ARRIVED BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {

                      await FirebaseFirestore.instance
                          .collection('rides')
                          .doc(widget.rideId)
                          .update({
                        "status": "arrived",
                      });

                      if (!context.mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DriverOTPPage(rideId: widget.rideId),
                        ),
                      );
                    },
                    child: const Text(
                      "I've Arrived",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }
}