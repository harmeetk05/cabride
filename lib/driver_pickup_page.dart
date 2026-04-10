import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'driver_otp_page.dart';

class DriverPickupPage extends StatelessWidget {
  final String rideId;

  const DriverPickupPage({super.key, required this.rideId});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Reach Pickup")),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text("Navigate to pickup location"),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DriverOTPPage(rideId: rideId),
                  ),
                );
              },
              child: const Text("Reached Pickup"),
            )
          ],
        ),
      ),
    );
  }
}