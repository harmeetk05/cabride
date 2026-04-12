import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'driver_pay_page.dart';
import 'EmergencyPage.dart';

class DriverRidePage extends StatefulWidget {
  final String rideId;

  const DriverRidePage({super.key, required this.rideId});

  @override
  State<DriverRidePage> createState() => _DriverRidePageState();
}

class _DriverRidePageState extends State<DriverRidePage> {
  int remainingSeconds = 25 * 60;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds == 0) {
        t.cancel();
      } else {
        setState(() => remainingSeconds--);
      }
    });
  }

  String formatTime(int s) =>
      "${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}";

  // 🔥 UPDATED: Now navigates instead of popup
  void emergency() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EmergencyPage(),
      ),
    );
  }

  Future<void> completeRide(Map<String, dynamic> rideData) async {
    await FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .update({
      "status": "completed",
      "paymentStatus": "pending",
    });

    await FirebaseFirestore.instance
        .collection('drivers')
        .doc(rideData['driverId'])
        .update({"active": true});

    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DriverPayPage(
          rideId: widget.rideId,
          userId: rideData['userId'],
          fare: rideData['fare'],
        ),
      ),
    );
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
        title: const Text("Active Ride"),
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
          var data = ride.data() as Map<String, dynamic>;
          bool warning = remainingSeconds < 300;

          return Column(
            children: [
              Container(
                height: 220,
                width: double.infinity,
                color: Colors.black87,
                child: const Center(
                  child: Icon(Icons.map, color: Colors.white, size: 60),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: warning ? Colors.red : Colors.black,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("ETA",
                                style: TextStyle(color: Colors.white70)),
                            Text(
                              formatTime(remainingSeconds),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Pickup"),
                            Text(
                              data['pickup'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Divider(),
                            const Text("Drop"),
                            Text(
                              data['drop'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: emergency,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text("Emergency"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => completeRide(data),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text("Complete"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}