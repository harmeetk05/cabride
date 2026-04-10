import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserPaymentPage extends StatelessWidget {
  const UserPaymentPage({super.key});

  void showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(20),
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                SizedBox(height: 20),
                Text(
                  "Payment Successful 🎉",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Your Payments")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .where('userId', isEqualTo: userId)
            .where('paymentStatus', isEqualTo: 'unpaid')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var rides = snapshot.data!.docs;

          if (rides.isEmpty) {
            return const Center(child: Text("No pending payments"));
          }

          return ListView.builder(
            itemCount: rides.length,
            itemBuilder: (context, index) {
              var ride = rides[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text("Fare: ₹${ride['fare']}"),
                  subtitle: Text("Status: ${ride['status']}"),
                  trailing: ElevatedButton(
                    child: const Text("Pay Cash"),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('rides')
                          .doc(ride.id)
                          .update({
                        "paymentStatus": "paid",
                        "paymentMethod": "cash",
                      });
if (!context.mounted)return;
                      showSuccessDialog(context);
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