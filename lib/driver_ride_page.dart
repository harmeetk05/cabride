import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverRidePage extends StatelessWidget {
  final String rideId;

  const DriverRidePage({super.key, required this.rideId});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Ride in Progress")),

      body: Center(
        child: ElevatedButton(
          child: const Text("Complete Ride"),
          onPressed: () async {

            var ride = await FirebaseFirestore.instance
                .collection('rides')
                .doc(rideId)
                .get();

            String driverId = ride['driverId'];

            await FirebaseFirestore.instance
                .collection('rides')
                .doc(rideId)
                .update({"status": "completed"});

            await FirebaseFirestore.instance
                .collection('drivers')
                .doc(driverId)
                .update({"available": true});

            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}