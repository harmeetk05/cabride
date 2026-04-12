import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'main.dart';

class DriverFeedbackPage extends StatefulWidget {
  final String rideId;
  final String userId;

  const DriverFeedbackPage({
    super.key,
    required this.rideId,
    required this.userId,
  });

  @override
  State<DriverFeedbackPage> createState() => _DriverFeedbackPageState();
}

class _DriverFeedbackPageState extends State<DriverFeedbackPage> {
  double rating = 3;
  final commentController = TextEditingController();

  Future<void> submit() async {
    String driverId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('feedback').add({
      "rideId": widget.rideId,
      "fromId": driverId,
      "toId": widget.userId,
      "fromRole": "driver",
      "rating": rating,
      "comment": commentController.text,
      "createdAt": Timestamp.now(),
    });

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DriverHome()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Rate Passenger"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.star, size: 60, color: Colors.amber),

            const SizedBox(height: 20),

            Slider(
              value: rating,
              min: 1,
              max: 5,
              divisions: 4,
              label: rating.toString(),
              onChanged: (v) => setState(() => rating = v),
            ),

            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                hintText: "Write feedback...",
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text("Finish Ride"),
            ),
          ],
        ),
      ),
    );
  }
}