import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverPaymentsPage extends StatelessWidget {
  const DriverPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    String driverId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Driver Payments")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .where('driverId', isEqualTo: driverId)
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
                  subtitle: Text("Payment: ${ride['paymentStatus']}"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}