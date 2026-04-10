import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserFeedbackPage extends StatefulWidget {

  final String rideId;
  final String driverId;

  const UserFeedbackPage({
    super.key,
    required this.rideId,
    required this.driverId,
  });

  @override
  State<UserFeedbackPage> createState() => _UserFeedbackPageState();
}

class _UserFeedbackPageState extends State<UserFeedbackPage> {

  double rating = 3;
  final commentController = TextEditingController();

  Future<void> submitFeedback() async {

    String userId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('feedback').add({
      "rideId": widget.rideId,
      "fromId": userId,
      "fromRole": "user",
      "toId": widget.driverId,
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
      appBar: AppBar(title: const Text("Rate Driver")),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const Text("Rating"),

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