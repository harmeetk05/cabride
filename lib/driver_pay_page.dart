import 'package:flutter/material.dart';
import 'driver_feedback_page.dart';

class DriverPayPage extends StatelessWidget {
  final String rideId;
  final String userId;
  final num fare;

  const DriverPayPage({
    super.key,
    required this.rideId,
    required this.userId,
    required this.fare,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.payments, size: 60, color: Colors.black),

              const SizedBox(height: 15),

              const Text(
                "Collect Fare",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Text(
                "₹$fare",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Ask passenger for cash / confirm payment",
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 25),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 45),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DriverFeedbackPage(
                        rideId: rideId,
                        userId: userId,
                      ),
                    ),
                  );
                },
                child: const Text("Payment Received"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}