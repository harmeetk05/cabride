import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageDriversPage extends StatelessWidget {
  const ManageDriversPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Drivers"), centerTitle: true),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('drivers').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var drivers = snapshot.data!.docs;

          if (drivers.isEmpty) {
            return const Center(child: Text("No drivers found"));
          }

          return ListView.builder(
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              var driver = drivers[index];
              var driverId = driver.id;
              var ratingData = driver['rating'] ?? {};

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Name and Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage:
                                    driver.data().containsKey('imageUrl')
                                    ? NetworkImage(driver['imageUrl'])
                                    : null,
                                child: !driver.data().containsKey('imageUrl')
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                driver['name'] ?? "Driver",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${ratingData['rating'] ?? 'N/A'}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 25),

                      // Basic Details
                      infoRow(Icons.phone, driver['phone'] ?? "No phone"),
                      infoRow(
                        Icons.location_on,
                        driver['address'] ?? "No address",
                      ),
                      infoRow(
                        Icons.person_outline,
                        "Gender: ${driver['gender'] ?? 'Not specified'}",
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "Vehicle Information",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Vehicle Details from separate collection
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('vehicles')
                            .doc(driverId)
                            .get(),
                        builder: (context, vehicleSnapshot) {
                          if (vehicleSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const LinearProgressIndicator();
                          }
                          if (!vehicleSnapshot.hasData ||
                              !vehicleSnapshot.data!.exists) {
                            return const Text(
                              "No vehicle allotted",
                              style: TextStyle(color: Colors.redAccent),
                            );
                          }

                          var v = vehicleSnapshot.data!;
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                vehicleDetailRow("Model", v['model']),
                                vehicleDetailRow("Number", v['number']),
                                vehicleDetailRow("Color", v['color']),
                                vehicleDetailRow("Capacity", v['capacity']),
                              ],
                            ),
                          );
                        },
                      ),
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

  // Helper for driver info rows
  Widget infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  // Helper for vehicle table rows
  Widget vehicleDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
