import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentLogsPage extends StatelessWidget {
  const PaymentLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment Logs"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .orderBy('createdAt', descending: true) // latest first
            .snapshots(),
        builder: (context, snapshot) {
          // 🔄 Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ❌ No data
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No payment records found"));
          }

          var rides = snapshot.data!.docs;

          return ListView.builder(
            itemCount: rides.length,
            itemBuilder: (context, index) {
              var ride = rides[index];

              // 🛡 Safe extraction (no crash even if field missing)
              String userId = ride['userId'] ?? 'Unknown';
              String driverId = ride['driverId'] ?? 'Unknown';
              String fare = ride['fare'] != null
                  ? "₹${ride['fare']}"
                  : "₹0";
              String paymentStatus = ride['paymentStatus'] ?? 'unpaid';
              String paymentMethod = ride['paymentMethod'] ?? 'N/A';
              String rideStatus = ride['status'] ?? 'unknown';

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: paymentStatus == "paid"
                        ? Colors.green
                        : Colors.orange,
                    child: const Icon(Icons.payment, color: Colors.white),
                  ),

                  // 🧾 MAIN INFO
                  title: Text(
                    fare,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  // 📄 DETAILS
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("User: $userId"),
                      Text("Driver: $driverId"),
                      Text("Ride Status: $rideStatus"),
                      Text("Method: $paymentMethod"),
                    ],
                  ),

                  // ✅ STATUS BADGE
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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