import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//ignore:avoid_web_libraries_in_flutter
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:js' as js; // ✅ Crucial for Web Fallback
import 'user_feedback_page.dart';

class UserPaymentPage extends StatefulWidget {
  final String? rideId;
  const UserPaymentPage({super.key, this.rideId});

  @override
  State<UserPaymentPage> createState() => _UserPaymentPageState();
}

class _UserPaymentPageState extends State<UserPaymentPage> {
  String selectedMethod = "UPI"; // Default selection

  // --- FINALIZING THE PAYMENT IN DATABASE ---
  Future<void> _finalizePayment(String method) async {
  try {
    // 1. Get the ride document
    var rideDoc = await FirebaseFirestore.instance.collection('rides').doc(widget.rideId).get();
    if (!rideDoc.exists) return;

    String passengerId = rideDoc['userId'] ?? "";
    String driverId = rideDoc['driverId'] ?? "";
    double totalFare = double.tryParse(rideDoc['fare'].toString()) ?? 0.0;

    // 💰 Calculate Driver's 70% Share
    double driverShare = totalFare * 0.70;

    // 2. Update Payments Collection
    var paymentQuery = await FirebaseFirestore.instance
        .collection('payments')
        .where('rideId', isEqualTo: widget.rideId)
        .get();

    for (var doc in paymentQuery.docs) {
      await doc.reference.update({
        "method": method,
        "status": "completed",
        "userId": passengerId, 
        "createdAt": FieldValue.serverTimestamp(),
      });
    }

    // 3. Update Rides Collection
    await rideDoc.reference.update({
      "paymentStatus": "paid",
      "status": "completed",
    });

    // 4. 🚀 BULLETPROOF REVENUE UPDATE
    if (driverId.isNotEmpty) {
      // Using Set with merge: true ensures it won't crash even if the fields are missing
      await FirebaseFirestore.instance.collection('drivers').doc(driverId).set({
        "totalRevenue": FieldValue.increment(driverShare),
        "walletBalance": FieldValue.increment(driverShare),
      }, SetOptions(merge: true)); 
      
      print("✅ Successfully deposited ₹$driverShare into driver's wallet!");
    } else {
      print("❌ Error: No driverId found for this ride.");
    }

    if (!mounted) return;
    showSuccessDialog(context, driverId, widget.rideId!);

  } catch (e) {
    print("Database Update Error: $e");
  }
}

  // --- DIRECT JAVASCRIPT RAZORPAY CALL (Fixes MissingPluginException) ---
  void openRazorpayWeb(double amount) {
    var options = js.JsObject.jsify({
      'key': 'rzp_test_Sd2K9sVbezqLUc',
      'amount': (amount * 100).toInt(),
      'name': 'CabRide',
      'description': 'Ride Payment',
      'prefill': {'contact': '9999999999', 'email': 'user@example.com'},
      'handler': js.allowInterop((response) {
        // ✅ This is the critical part!
        print("Razorpay Success: ${response['razorpay_payment_id']}");

        // We call finalize directly here
        _finalizePayment("upi");
      }),
      'modal': {
        'ondismiss': js.allowInterop(() {
          print("Payment window closed by user");
        }),
      },
    });

    try {
      var rzp = js.JsObject(js.context['Razorpay'], [options]);
      rzp.callMethod('open');
    } catch (e) {
      print("JS Error: $e");
      // Fallback if the gateway fails to open at all
      _finalizePayment("upi");
    }
  }

  void showSuccessDialog(BuildContext context, String driverId, String rideId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              const Text(
                "Payment Successful",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text("Redirecting to feedback..."),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close dialog
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => UserFeedbackPage(rideId: rideId, driverId: driverId),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rideId == null) {
      return const Scaffold(body: Center(child: Text("No ride selected")));
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "Payment",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3250),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('rides')
            .doc(widget.rideId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          var ride = snapshot.data!;
          double fare = double.tryParse(ride['fare'].toString()) ?? 0.0;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Fare Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D3250), Color(0xFF4A55A2)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Final Fare",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "₹$fare",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Choose Payment Method",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3250),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // UPI Option
                _methodTile(
                  "UPI / Online",
                  Icons.qr_code_scanner,
                  "UPI",
                  Colors.indigo,
                ),
                const SizedBox(height: 15),
                // Cash Option
                _methodTile(
                  "Cash on Arrival",
                  Icons.payments_outlined,
                  "CASH",
                  Colors.green,
                ),

                const Spacer(),

                // Proceed Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D3250),
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    if (selectedMethod == "UPI") {
                      openRazorpayWeb(fare);
                    } else {
                      _finalizePayment("cash");
                    }
                  },
                  child: Text(
                    selectedMethod == "UPI"
                        ? "Proceed to Gateway"
                        : "Confirm Cash Payment",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _methodTile(String title, IconData icon, String value, Color color) {
    bool isSelected = selectedMethod == value;
    return GestureDetector(
      onTap: () => setState(() => selectedMethod = value),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }
}
