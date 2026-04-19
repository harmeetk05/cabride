import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'driver_pickup_page.dart';

class DriverRequestsPage extends StatelessWidget {
  const DriverRequestsPage({super.key});

  Future<Map<String, dynamic>> _getDriverCapability() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    var driverDoc = await FirebaseFirestore.instance.collection('drivers').doc(uid).get();
    var vehicleDoc = await FirebaseFirestore.instance.collection('vehicles').doc(uid).get();

    return {
      "gender": driverDoc.data()?['gender'] ?? "male",
      "categories": List<String>.from(vehicleDoc.data()?['categories'] ?? ["Standard"]),
    };
  }

  @override
  Widget build(BuildContext context) {
    String driverId = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<Map<String, dynamic>>(
      future: _getDriverCapability(),
      builder: (context, capabilitySnap) {
        if (!capabilitySnap.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8F9FD),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF2D3250))),
          );
        }

        final driverGender = capabilitySnap.data!['gender'];
        final myCategories = capabilitySnap.data!['categories'];

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FD),
          appBar: AppBar(
            title: const Text("AVAILABLE JOBS", 
              style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 14)),
            backgroundColor: const Color(0xFF2D3250),
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(icon: const Icon(Icons.tune_rounded, size: 20), onPressed: () {}),
            ],
          ),
          body: Column(
            children: [
              // 📊 STATUS HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF2D3250),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.greenAccent,
                      radius: 4,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "ONLINE • ${myCategories.join(", ")}".toUpperCase(),
                      style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('rides')
                      .where('status', isEqualTo: 'searching')
                      .where('vehicle', whereIn: myCategories)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    var rides = snapshot.data!.docs.where((doc) {
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                      List rejectedBy = data['rejectedBy'] ?? [];
                      if (rejectedBy.contains(driverId)) return false;
                      bool femaleOnly = data['femaleOnly'] ?? false;
                      if (femaleOnly && driverGender != "female") return false;
                      return true;
                    }).toList();

                    if (rides.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0.8, end: 1.2),
                              duration: const Duration(seconds: 2),
                              curve: Curves.easeInOut,
                              builder: (context, double val, child) {
                                return Transform.scale(
                                  scale: val,
                                  child: Icon(Icons.radar_rounded, size: 80, color: const Color(0xFF2D3250).withOpacity(0.1)),
                                );
                              },
                              onEnd: () {}, // Handled by builder repeat if logic added, but native pulse works here
                            ),
                            const SizedBox(height: 20),
                            const Text("WATCHING FOR REQUESTS", 
                              style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                      itemCount: rides.length,
                      itemBuilder: (context, index) {
                        var ride = rides[index];
                        Map<String, dynamic> rideData = ride.data() as Map<String, dynamic>;
                        bool isPremium = rideData['vehicle'] != "Standard";

                        return TweenAnimationBuilder(
                          duration: Duration(milliseconds: 400 + (index * 100)),
                          tween: Tween<double>(begin: 0, end: 1),
                          builder: (context, double value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2D3250).withOpacity(0.06),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Column(
                                children: [
                                  // TOP BAR PIN
                                  Container(
                                    height: 4,
                                    width: double.infinity,
                                    color: isPremium ? Colors.amber : const Color(0xFF2D3250).withOpacity(0.1),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F4FF),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(rideData['vehicle'].toUpperCase(), 
                                                style: const TextStyle(color: Color(0xFF2D3250), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                            ),
                                            Text("₹${rideData['fare']}", 
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF2D3250))),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        _buildLocationRow(Icons.radio_button_checked_rounded, Colors.greenAccent.shade700, rideData['pickup']['address']),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 9),
                                          child: Align(alignment: Alignment.centerLeft, child: Container(width: 2, height: 15, color: Colors.grey.shade100)),
                                        ),
                                        _buildLocationRow(Icons.location_on_rounded, Colors.redAccent, rideData['drop']['address']),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(color: const Color(0xFFF8F9FD)),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () async {
                                              await FirebaseFirestore.instance.collection('rides').doc(ride.id).update({
                                                "rejectedBy": FieldValue.arrayUnion([driverId])
                                              });
                                            },
                                            child: const Text("IGNORE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          flex: 2,
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              try {
                                                await FirebaseFirestore.instance.runTransaction((transaction) async {
                                                  DocumentReference rideRef = FirebaseFirestore.instance.collection('rides').doc(ride.id);
                                                  DocumentReference driverRef = FirebaseFirestore.instance.collection('drivers').doc(driverId);
                                                  DocumentSnapshot rideSnap = await transaction.get(rideRef);
                                                  if (rideSnap['status'] != 'searching') throw "RIDE_TAKEN";
                                                  transaction.update(rideRef, {"status": "assigned", "driverId": driverId});
                                                  transaction.update(driverRef, {"active": false});
                                                });
                                                if (!context.mounted) return;
                                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DriverPickupPage(rideId: ride.id)));
                                              } catch (e) {
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e == "RIDE_TAKEN" ? "Ride already assigned" : "Error accepting ride")));
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF2D3250),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(vertical: 15),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                            ),
                                            child: const Text("ACCEPT RIDE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                                          ),
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String address) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 15),
        Expanded(
          child: Text(address, 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis, 
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3250))),
        ),
      ],
    );
  }
}