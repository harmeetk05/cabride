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
      appBar: AppBar(
        title: const Text("New Ride Requests"),
        backgroundColor: Colors.black,
      ),

      // 🔥 DUMMY RIDE BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: const Icon(Icons.flash_on),
        onPressed: () async {

          await FirebaseFirestore.instance.collection('rides').add({
            "pickup": "Demo Pickup",
            "drop": "Demo Destination",
            "fare": 120,
            "status": "searching",
            "driverId": null,
            "userId": "demoUser",
            "paymentStatus": "unpaid",
            "femaleOnly": false,
            "createdAt": Timestamp.now(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Demo ride created")),
          );
        },
      ),

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
            return const Center(
              child: Text(
                "No requests right now",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: rides.length,
            itemBuilder: (context, index) {

              var ride = rides[index];

              return Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6)
                  ],
                ),

                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // 📍 PICKUP
                      Row(
                        children: [
                          const Icon(Icons.radio_button_checked, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ride['pickup'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // 📍 DROP
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(ride['drop']),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // 💰 + BUTTON
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                          Text(
                            "₹${ride['fare']}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                            ),
                            child: const Text("Accept"),

                            onPressed: () async {

                              String rideId = ride.id;

                              try {
                                await FirebaseFirestore.instance
                                    .runTransaction((transaction) async {

                                  DocumentReference rideRef =
                                      FirebaseFirestore.instance
                                          .collection('rides')
                                          .doc(rideId);

                                  DocumentSnapshot rideSnap =
                                      await transaction.get(rideRef);

                                  if (rideSnap['status'] != 'searching') {
                                    throw Exception("Taken");
                                  }

                                  // ✅ Assign driver
                                  transaction.update(rideRef, {
                                    "driverId": driverId,
                                    "status": "assigned",
                                  });

                                  // ✅ Make driver busy
                                  DocumentReference driverRef =
                                      FirebaseFirestore.instance
                                          .collection('drivers')
                                          .doc(driverId);

                                  transaction.update(driverRef, {
                                    "active": false,
                                  });
                                });

                                if (!context.mounted) return;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DriverPickupPage(
                                      rideId: rideId,
                                    ),
                                  ),
                                );

                              } catch (e) {

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Ride already accepted by another driver"),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      )
                    ],
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