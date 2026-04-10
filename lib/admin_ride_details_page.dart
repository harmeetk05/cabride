import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRideDetailsPage extends StatelessWidget {

  final String rideId;

  const AdminRideDetailsPage({super.key, required this.rideId});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ride Details"),
        backgroundColor: Colors.black,
      ),

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

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text("Ride ID: $rideId",
                    style: const TextStyle(fontWeight: FontWeight.bold)),

                const SizedBox(height: 10),

                Text("User ID: ${ride['userId']}"),
                Text("Driver ID: ${ride['driverId'] ?? "Not Assigned"}"),

                const SizedBox(height: 10),

                Text("Pickup: ${ride['pickupText'] ?? ""}"),
                Text("Drop: ${ride['dropText'] ?? ""}"),

                const SizedBox(height: 10),

                Text("Fare: ₹${ride['fare'] ?? 0}"),
                Text("Payment Status: ${ride['paymentStatus'] ?? "unpaid"}"),
                Text("Ride Status: ${ride['status']}"),

                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('rides')
                        .doc(rideId)
                        .update({"status": "cancelled"});

                    Navigator.pop(context);
                  },
                  child: const Text("Cancel Ride"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}