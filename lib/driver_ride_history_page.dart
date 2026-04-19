import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DriverRidesHistoryPage extends StatelessWidget {
  const DriverRidesHistoryPage({super.key});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'ongoing': return Colors.blue;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Ride History", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2D3250),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .where('driverId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2D3250)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🔥 Corrected lowercase getter
                  Icon(Icons.directions_car_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 15),
                  const Text("No ride history yet", style: TextStyle(color: Colors.grey, fontSize: 18)),
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
              String userId = ride['userId'] ?? "";

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03), 
                      blurRadius: 10, 
                      offset: const Offset(0, 4)
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // TOP ROW: Date and Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[400]),
                              const SizedBox(width: 6),
                              Text(DateFormat('dd MMM yyyy, hh:mm a').format(date), 
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(status.toUpperCase(), 
                                style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                      
                      // MIDDLE SECTION: Route & Fare
                      Row(
                        children: [
                          // Route Visualizer
                          Column(
                            children: [
                              const Icon(Icons.circle, size: 10, color: Colors.green),
                              Container(width: 1, height: 20, color: Colors.grey[200]),
                              const Icon(Icons.location_on, size: 14, color: Colors.red),
                            ],
                          ),
                          const SizedBox(width: 15),
                          // Address Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ride['pickup']['address'] ?? ride['pickup'], 
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 12),
                                Text(ride['drop']['address'] ?? ride['drop'], 
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          // Fare
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("₹${ride['fare']}", 
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3250))),
                              const Text("Fare", style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 15),
                      
                      // BOTTOM ROW: Passenger Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person_outline, size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 8),
                            const Text("Passenger: ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                              builder: (context, userSnap) {
                                if (!userSnap.hasData) return const Text("...", style: TextStyle(fontSize: 12));
                                var name = (userSnap.data!.data() as Map<String, dynamic>?)?['name'] ?? "User";
                                return Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2D3250)));
                              },
                            ),
                            const Spacer(),
                            Text(ride['vehicle'] ?? "Standard", style: TextStyle(fontSize: 11, color: Colors.grey[400], fontStyle: FontStyle.italic)),
                          ],
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