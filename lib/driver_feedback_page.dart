import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> submitFeedback() async {

    String driverId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('feedback').add({
      "rideId": widget.rideId,
      "fromId": driverId,
      "fromRole": "driver",
      "toId": widget.userId,
      "rating": rating,
      "comment": commentController.text,
      "createdAt": Timestamp.now(),
    });

    if (!context.mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Rate User")),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

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
              decoration: const InputDecoration(labelText: "Comment"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: submitFeedback,
              child: const Text("Submit"),
            )
          ],
        ),
      ),
    );
  }
}