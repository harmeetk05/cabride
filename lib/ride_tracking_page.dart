import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_feedback_page.dart';

class RideTrackingPage extends StatelessWidget {
  final String rideId;

  const RideTrackingPage({super.key, required this.rideId});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Ride Tracking")),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .doc(rideId)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var ride = snapshot.data!;

          if (ride['status'] == "completed") {
            Future.microtask(() {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => UserFeedbackPage(
                    rideId: rideId,
                    driverId: ride['driverId'],
                  ),
                ),
              );
            });
          }

          return FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('drivers')
                .doc(ride['driverId'])
                .get(),
            builder: (context, driverSnap) {

              if (!driverSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var driver = driverSnap.data!;

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [

                    Text("Driver: ${driver['name']}"),
                    Text("Vehicle: ${driver['vehicle']}"),

                    const SizedBox(height: 20),

                    const Text("Your OTP: 1234",
                        style: TextStyle(fontSize: 20)),

                    const SizedBox(height: 30),

                    ElevatedButton(
                      onPressed: () {},
                      child: const Text("Call Driver"),
                    ),

                    ElevatedButton(
                      onPressed: () {},
                      child: const Text("Emergency"),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}