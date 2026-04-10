import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_ride_details_page.dart';

class AdminRidesDashboard extends StatelessWidget {
  const AdminRidesDashboard({super.key});

  Color getStatusColor(String status) {
    switch (status) {
      case "searching":
        return Colors.orange;
      case "accepted":
        return Colors.blue;
      case "ongoing":
        return Colors.green;
      case "completed":
        return Colors.grey;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Rides"),
        backgroundColor: Colors.black,
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var rides = snapshot.data!.docs;

          if (rides.isEmpty) {
            return const Center(child: Text("No rides yet"));
          }

          return ListView.builder(
            itemCount: rides.length,
            itemBuilder: (context, index) {

              var ride = rides[index];

              String status = ride['status'] ?? "unknown";

              return Card(
                margin: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(

                  leading: CircleAvatar(
                    backgroundColor: getStatusColor(status),
                    child: const Icon(Icons.directions_car, color: Colors.white),
                  ),

                  title: Text("Ride ID: ${ride.id}"),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("User: ${ride['userId']}"),
                      Text("Driver: ${ride['driverId'] ?? "Not Assigned"}"),
                      Text("Fare: ₹${ride['fare'] ?? 0}"),
                      Text("Status: $status"),
                    ],
                  ),

                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: "view", child: Text("View Details")),
                      const PopupMenuItem(value: "cancel", child: Text("Cancel Ride")),
                    ],
                    onSelected: (value) {
                      if (value == "view") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminRideDetailsPage(rideId: ride.id),
                          ),
                        );
                      } else if (value == "cancel") {
                        FirebaseFirestore.instance
                            .collection('rides')
                            .doc(ride.id)
                            .update({"status": "cancelled"});
                      }
                    },
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