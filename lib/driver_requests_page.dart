import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'driver_pickup_page.dart';

class DriverRequestsPage extends StatelessWidget {
  const DriverRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {

    String driverId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("New Ride Requests")),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .where('status', isEqualTo: 'searching')
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var rides = snapshot.data!.docs;

          if (rides.isEmpty) {
            return const Center(child: Text("No requests right now"));
          }

          return ListView.builder(
            itemCount: rides.length,
            itemBuilder: (context, index) {

              var ride = rides[index];

              return Card(
                child: ListTile(
                  title: Text("Pickup: ${ride['pickup']}"),
                  subtitle: Text("Drop: ${ride['drop']}"),
                  trailing: ElevatedButton(
                    child: const Text("Accept"),
                    onPressed: () async {

                      await FirebaseFirestore.instance
                          .collection('rides')
                          .doc(ride.id)
                          .update({
                        "driverId": driverId,
                        "status": "assigned",
                      });

                      await FirebaseFirestore.instance
                          .collection('drivers')
                          .doc(driverId)
                          .update({"available": false});

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DriverPickupPage(
                            rideId: ride.id,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}