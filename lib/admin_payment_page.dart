import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPaymentLogsPage extends StatelessWidget {
  const AdminPaymentLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Payments")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var rides = snapshot.data!.docs;

          return ListView.builder(
            itemCount: rides.length,
            itemBuilder: (context, index) {
              var ride = rides[index];

              return Card(
                child: ListTile(
                  title: Text("₹${ride['fare']}"),
                  subtitle: Text(
                      "User: ${ride['userId']}\nDriver: ${ride['driverId']}"),
                  trailing: Text(ride['paymentStatus']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}