import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';

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
    "toId": widget.driverId,
    "fromRole": "user", 
    "rating": rating,
    "comment": commentController.text,
    "createdAt": Timestamp.now(),
  });

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Feedback submitted")),
  );

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const UserHome()),
    (route) => false,
  );
}

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Rate Driver")),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const Text(
              "How was your ride?",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Slider(
              value: rating,
              min: 1,
              max: 5,
              divisions: 4,
              label: rating.toString(),
              onChanged: (v) => setState(() => rating = v),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: "Write a comment (optional)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: submitFeedback,
              child: const Text("Submit Feedback"),
            )
          ],
        ),
      ),
    );
  }
}