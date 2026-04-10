import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageDriversPage extends StatelessWidget {
  const ManageDriversPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Drivers"),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('drivers').snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var drivers = snapshot.data!.docs;

          if (drivers.isEmpty) {
            return const Center(child: Text("No drivers found"));
          }

          return ListView.builder(
            itemCount: drivers.length,
            itemBuilder: (context, index) {

              var driver = drivers[index];

              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.drive_eta),
                  ),
                  title: Text(driver['name'] ?? "Driver"),
                  subtitle: Text(driver['phone'] ?? "No phone"),
                ),
              );

            },
          );
        },
      ),
    );
  }
}