import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_payment_page.dart';
import 'EmergencyPage.dart';

class RideTrackingPage extends StatelessWidget {
  final String rideId;

  const RideTrackingPage({super.key, required this.rideId});

  void openEmergency(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmergencyPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Your Ride"),
        backgroundColor: Colors.black,
      ),

      body: SafeArea(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('rides')
              .doc(rideId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var ride = snapshot.data!;

            if (ride['driverId'] == null) {
              return const Center(
                child: Text(
                  "Still finding a driver...",
                  style: TextStyle(fontSize: 16),
                ),
              );
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
                var data = driver.data() as Map<String, dynamic>;
                var vehicle = data['vehicle'] ?? {};

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // 🚗 DRIVER CARD
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 8),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: data.containsKey("imageUrl")
                                    ? NetworkImage(data['imageUrl'])
                                    : null,
                                child: data.containsKey("imageUrl")
                                    ? null
                                    : const Icon(Icons.person),
                              ),

                              const SizedBox(width: 15),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['name'] ?? "Driver",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "${vehicle['model'] ?? ''} • ${vehicle['color'] ?? ''}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      "No: ${vehicle['number'] ?? ''}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Column(
                                children: [
                                  const Icon(Icons.star, color: Colors.orange),
                                  Text(
                                    data['rating']?['rating']?.toString() ??
                                        "4.5",
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 🔐 OTP CARD
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            children: [
                              Text(
                                "Your OTP",
                                style: TextStyle(color: Colors.white70),
                              ),
                              SizedBox(height: 10),
                              Text(
                                "1234",
                                style: TextStyle(
                                  fontSize: 28,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // 🎯 ACTIONS
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.call),
                                label: const Text("Call"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () => openEmergency(context),
                                icon: const Icon(Icons.warning),
                                label: const Text("Emergency"),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // ✅ COMPLETE RIDE BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: const Text("Complete Ride"),
                            onPressed: () async {
                              String driverId = ride['driverId'];
                              String currentRideId =
                                  rideId; // Using the rideId variable from the widget

                              // 1. Update Firestore status
                              await FirebaseFirestore.instance
                                  .collection('rides')
                                  .doc(currentRideId)
                                  .update({
                                    "status": "completed",
                                    "paymentStatus": "unpaid",
                                  });

                              // 2. Navigate to your Payment Page
                              if (context.mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UserPaymentPage(rideId: currentRideId),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
