import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminRideDetailsPage extends StatelessWidget {
  final String rideId;

  const AdminRideDetailsPage({super.key, required this.rideId});

  // Helper to get color based on status
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Ride Audit", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2D3250),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('rides').doc(rideId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists) return const Center(child: Text("Ride no longer exists."));

          var ride = snapshot.data!.data() as Map<String, dynamic>;
          String userId = ride['userId'] ?? "";
          String? driverId = ride['driverId'];

          // 🔥 Modern Admin Strategy: Fetch real names instead of showing IDs
          return FutureBuilder(
            future: Future.wait([
              FirebaseFirestore.instance.collection('users').doc(userId).get(),
              driverId != null 
                ? FirebaseFirestore.instance.collection('drivers').doc(driverId).get() 
                : Future.value(null),
            ]),
            builder: (context, AsyncSnapshot<List<dynamic>> peopleSnap) {
              if (!peopleSnap.hasData) return const Center(child: CircularProgressIndicator());

              var userData = peopleSnap.data![0].data() as Map<String, dynamic>?;
              var driverData = peopleSnap.data![1]?.data() as Map<String, dynamic>?;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // 🎫 TOP STATUS HEADER
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("RIDE ID", style: TextStyle(color: Colors.grey[400], fontSize: 10, letterSpacing: 1.2)),
                              Text("#${rideId.substring(0, 8).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(ride['status']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              ride['status'].toString().toUpperCase(),
                              style: TextStyle(color: _getStatusColor(ride['status']), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 👥 PEOPLE INVOLVED SECTION
                    _sectionHeader("Involved Parties"),
                    Row(
                      children: [
                        _personCard("Passenger", userData?['name'] ?? "Unknown", Icons.person, Colors.blue),
                        const SizedBox(width: 15),
                        _personCard("Driver", driverData?['name'] ?? "Not Assigned", Icons.drive_eta, Colors.indigo),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // 📍 ROUTE INFORMATION (Google Maps Integrated Data)
                    _sectionHeader("Route Details"),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        children: [
                          _locationRow(ride['pickup']['address'] ?? "Unknown Pickup", Colors.green, "Pickup"),
                          const Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Divider(height: 30),
                          ),
                          _locationRow(ride['drop']['address'] ?? "Unknown Drop", Colors.red, "Destination"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // 💰 FINANCIALS & TECH
                    _sectionHeader("Financial Summary"),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        children: [
                          _dataRow("Total Fare", "₹${ride['fare']}", isBold: true),
                          _dataRow("Distance", "${ride['distance']} km"),
                          _dataRow("Payment Status", ride['paymentStatus'].toString().toUpperCase()),
                          _dataRow("OTP Used", ride['otp'] ?? "N/A"),
                          _dataRow("Vehicle Type", ride['vehicle'] ?? "N/A"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 🛠️ ADMIN ACTIONS
                    if (ride['status'] != 'cancelled' && ride['status'] != 'completed')
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                          onPressed: () => _confirmCancel(context),
                          icon: const Icon(Icons.block),
                          label: const Text("Terminate Ride Session", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Widget _personCard(String role, String name, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
            const SizedBox(height: 10),
            Text(role, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _locationRow(String address, Color color, String label) {
    return Row(
      children: [
        Icon(Icons.location_on, color: color, size: 20),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: TextStyle(color: Colors.grey[400], fontSize: 9, letterSpacing: 1)),
              Text(address, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dataRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 14, color: const Color(0xFF2D3250))),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Terminate Ride?"),
        content: const Text("This action will force cancel the ride for both the user and driver. This is recorded in admin logs."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Dismiss")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('rides').doc(rideId).update({"status": "cancelled"});
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Terminate"),
          ),
        ],
      ),
    );
  }
}