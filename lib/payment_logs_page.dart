import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentLogsPage extends StatelessWidget {
  const PaymentLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment Logs")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No payment records found"));
          }

          var rides = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              var ride = rides[index];
              final data = ride.data() as Map<String, dynamic>;

              String userId = data['userId'] ?? 'Unknown';
              String driverId = data['driverId'] ?? 'Unknown';
              num fare = data['fare'] ?? 0;

              String paymentStatus = data['paymentStatus'] ?? 'unpaid';
              String paymentMethod = data['paymentMethod'] ?? 'N/A';
              String rideStatus = data['status'] ?? 'unknown';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: paymentStatus == "paid"
                        ? Colors.green
                        : Colors.orange,
                    child: const Icon(Icons.payment, color: Colors.white),
                  ),

                  title: Text(
                    "₹$fare",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("User: $userId"),
                      Text("Driver: $driverId"),
                      Text("Ride Status: $rideStatus"),
                      Text("Method: $paymentMethod"),
                    ],
                  ),

                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: paymentStatus == "paid"
                          ? Colors.green
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      paymentStatus.toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
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