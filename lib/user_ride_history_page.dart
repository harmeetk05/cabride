import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class UserRidesHistoryPage extends StatelessWidget {
  const UserRidesHistoryPage({super.key});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'ongoing': return Colors.blue;
      case 'searching': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("My Ride History", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2D3250),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center),
            ));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2D3250)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 15),
                  const Text("No rides taken yet", style: TextStyle(color: Colors.grey, fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var ride = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              DateTime date = (ride['createdAt'] as Timestamp).toDate();
              String status = ride['status'] ?? "Unknown";
              String? driverId = ride['driverId'];

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        status == 'completed' ? Icons.done_all : (status == 'cancelled' ? Icons.close : Icons.local_taxi),
                        color: _getStatusColor(status),
                        size: 24,
                      ),
                    ),
                    title: Text(
                      DateFormat('EEE, dd MMM yyyy').format(date),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3250)),
                    ),
                    subtitle: Text(
                      DateFormat('hh:mm a').format(date),
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("₹${ride['fare']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3250))),
                        Text(status.toUpperCase(), style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 10),
                        child: Column(
                          children: [
                            const Divider(),
                            const SizedBox(height: 10),
                            // 📍 ROUTE VISUAL
                            _buildRouteRow(ride['pickup']['address'] ?? ride['pickup'], Colors.green, "Pickup"),
                            const SizedBox(height: 15),
                            _buildRouteRow(ride['drop']['address'] ?? ride['drop'], Colors.red, "Drop-off"),
                            
                            const SizedBox(height: 20),
                            
                            // 🚗 DRIVER & VEHICLE INFO
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FD),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                children: [
                                  _buildInfoRow("Vehicle Type", ride['vehicle'] ?? "Standard"),
                                  if (driverId != null) ...[
                                    const SizedBox(height: 10),
                                    FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance.collection('drivers').doc(driverId).get(),
                                      builder: (context, driverSnap) {
                                        if (!driverSnap.hasData) return const SizedBox();
                                        var dData = driverSnap.data!.data() as Map<String, dynamic>?;
                                        return _buildInfoRow("Driver", dData?['name'] ?? "Assigned");
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
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

  Widget _buildRouteRow(String address, Color color, String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(Icons.circle, size: 12, color: color),
            Container(width: 2, height: 20, color: Colors.grey[200]),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Text(address, style: const TextStyle(fontSize: 14, color: Color(0xFF2D3250), fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2D3250))),
      ],
    );
  }
}