import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageUsersPage extends StatelessWidget {
  const ManageUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Users"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          // ✅ Filter only normal users (exclude admin)
          var users = snapshot.data!.docs
              .where((doc) =>
                  doc.data().toString().contains('role') &&
                  doc['role'] == 'user')
              .toList();

          if (users.isEmpty) {
            return const Center(child: Text("No users available"));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 👤 NAME
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 22,
                            child: Icon(Icons.person),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            user['name'] ?? "No Name",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // 📧 EMAIL
                      Text("📧 Email: ${user['email'] ?? 'N/A'}"),

                      // 📱 PHONE
                      Text("📱 Phone: ${user['phone'] ?? 'N/A'}"),

                      // 🚨 EMERGENCY CONTACT
                      Text(
                          "🚨 Emergency: ${user['emergencyContact'] ?? 'N/A'}"),

                      // ☎ CONTACT PHONE
                      Text(
                          "☎ Contact Phone: ${user['contactPhone'] ?? 'N/A'}"),

                      // 👥 RELATION
                      Text("👥 Relation: ${user['relation'] ?? 'N/A'}"),

                      // 🩺 MEDICAL NOTES
                      Text(
                          "🩺 Medical: ${user['medicalNotes'] ?? 'N/A'}"),

                      const SizedBox(height: 6),

                      // 🕒 CREATED DATE
                      Text(
                        "🕒 Joined: ${user['createdAt'] != null ? (user['createdAt'] as Timestamp).toDate().toString() : 'N/A'}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
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