import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_ride_details_page.dart';
import 'package:intl/intl.dart';

class AdminRidesDashboard extends StatelessWidget {
  const AdminRidesDashboard({super.key});

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "searching": return Colors.orange;
      case "assigned": return Colors.blue;
      case "ongoing": return Colors.indigo;
      case "completed": return Colors.green;
      case "cancelled": return Colors.red;
      default: return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Ride Management", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF2D3250),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF2D3250)));

          var rides = snapshot.data!.docs;

          if (rides.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car_filled_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text("No ride activity found", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              var ride = rides[index];
              final data = ride.data() as Map<String, dynamic>;
              String status = data['status'] ?? 'unknown';
              
              // Formatting Timestamp
              String time = "N/A";
              if (data['createdAt'] != null) {
                time = DateFormat('jm').format((data['createdAt'] as Timestamp).toDate());
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AdminRideDetailsPage(rideId: ride.id)),
                    ),
                    child: Column(
                      children: [
                        // --- TOP STRIP ---
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          color: getStatusColor(status).withOpacity(0.08),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("ID: #${ride.id.substring(0, 6).toUpperCase()}",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: getStatusColor(status), fontSize: 12)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: getStatusColor(status),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(status.toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),

                        // --- DETAILS ---
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Pickup/Drop Visual
                              Column(
                                children: [
                                  const Icon(Icons.radio_button_checked, size: 16, color: Colors.green),
                                  Container(width: 2, height: 20, color: Colors.grey[200]),
                                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                                ],
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['pickup'] is Map ? data['pickup']['address'] : data['pickup'] ?? "Pickup",
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 12),
                                    Text(data['drop'] is Map ? data['drop']['address'] : data['drop'] ?? "Destination",
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("₹${data['fare']}",
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3250))),
                                  Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // --- QUICK ACTIONS BAR ---
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => AdminRideDetailsPage(rideId: ride.id)),
                                ),
                                icon: const Icon(Icons.analytics_outlined, size: 18),
                                label: const Text("Audit Trail"),
                                style: TextButton.styleFrom(foregroundColor: const Color(0xFF2D3250)),
                              ),
                              if (status != 'cancelled' && status != 'completed')
                                IconButton(
                                  icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
                                  onPressed: () => _showCancelDialog(context, ride.id),
                                ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String rideId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Admin Override"),
        content: const Text("Are you sure you want to terminate this ride? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Back")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              FirebaseFirestore.instance.collection('rides').doc(rideId).update({"status": "cancelled"});
              Navigator.pop(context);
            },
            child: const Text("Cancel Ride"),
          ),
        ],
      ),
    );
  }
}