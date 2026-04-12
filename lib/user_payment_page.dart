import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_feedback_page.dart';

class UserPaymentPage extends StatelessWidget {
  final String? rideId;

  const UserPaymentPage({super.key, this.rideId});

  void showSuccessDialog(
      BuildContext context, String driverId, String rideId) {

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Dialog(
          child: SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle,
                      color: Colors.green, size: 60),
                  SizedBox(height: 20),
                  Text(
                    "Payment Successful 🎉",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // close dialog

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => UserFeedbackPage(
            rideId: rideId, // ✅ always valid now
            driverId: driverId,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🚨 Safety check
    if (rideId == null) {
      return const Scaffold(
        body: Center(child: Text("No ride selected")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),

      body: FutureBuilder(
        future: FirebaseFirestore.instance
            .collection('rides')
            .doc(rideId)
            .get(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var ride = snapshot.data!;

          return Center(
            child: Card(
              margin: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    const Text(
                      "Complete Your Payment",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      "Fare: ₹${ride['fare']}",
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 25),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 14),
                      ),
                      child: const Text("Pay Cash"),
                      onPressed: () async {

                        await FirebaseFirestore.instance
                            .collection('rides')
                            .doc(rideId)
                            .update({
                          "paymentStatus": "paid",
                          "paymentMethod": "cash",
                        });

                        var paymentQuery = await FirebaseFirestore.instance
                            .collection('payments')
                            .where('rideId', isEqualTo: rideId)
                            .get();

                        for (var doc in paymentQuery.docs) {
                          await doc.reference.update({
                            "method": "cash",
                            "status": "completed",
                          });
                        }

                        if (!context.mounted) return;

                        showSuccessDialog(
                          context,
                          ride['driverId'],
                          rideId!, // ✅ safe now
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}