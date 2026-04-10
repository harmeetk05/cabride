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

          return ListView.builder(
            itemCount: feedbacks.length,
            itemBuilder: (context, index) {

              var fb = feedbacks[index];

              return Card(
                child: ListTile(
                  title: Text("Rating: ${fb['rating']}"),
                  subtitle: Text(
                      "Comment: ${fb['comment']}\nFrom: ${fb['fromRole']}"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}