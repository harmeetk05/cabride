import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'driver_ride_page.dart';

class DriverOTPPage extends StatefulWidget {
  final String rideId;

  const DriverOTPPage({super.key, required this.rideId});

  @override
  State<DriverOTPPage> createState() => _DriverOTPPageState();
}

class _DriverOTPPageState extends State<DriverOTPPage> {

  final otpController = TextEditingController();
  String error = "";

  Future<void> verifyOTP() async {

    var ride = await FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .get();

    String userId = ride['userId'];

    var user = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    String userOtp = user['otp']; // FIXED OTP

    if (otpController.text == userOtp) {

      await FirebaseFirestore.instance
          .collection('rides')
          .doc(widget.rideId)
          .update({"status": "ongoing"});

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DriverRidePage(rideId: widget.rideId),
        ),
      );

    } else {
      setState(() {
        error = "Wrong OTP";
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Enter OTP")),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Enter OTP",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: verifyOTP,
              child: const Text("Verify & Start Ride"),
            ),

            Text(error, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}