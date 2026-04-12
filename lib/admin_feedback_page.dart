import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFeedbackPage extends StatelessWidget {
  const AdminFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Feedback")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('feedback')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var feedbacks = snapshot.data!.docs;

          if (feedbacks.isEmpty) {
            return const Center(child: Text("No feedback yet"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: feedbacks.length,
            itemBuilder: (context, index) {
              var fb = feedbacks[index];
              final data = fb.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.feedback, color: Colors.blue),
                  title: Text("⭐ Rating: ${data['rating'] ?? 'N/A'}"),
                  subtitle: Text(
                  "Comment: ${data['comment'] ?? 'No comment'}\n"
                  "From: ${data['fromRole'] ?? 'unknown'}",
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