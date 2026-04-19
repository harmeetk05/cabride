import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'driver_otp_page.dart';
import 'main.dart';

class DriverPickupPage extends StatefulWidget {
  final String rideId;

  const DriverPickupPage({super.key, required this.rideId});

  @override
  State<DriverPickupPage> createState() => _DriverPickupPageState();
}

class _DriverPickupPageState extends State<DriverPickupPage> with SingleTickerProviderStateMixin {
  int remainingSeconds = 300; // 5 minutes
  Timer? timer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    startTimer();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not dial: $phoneNumber")),
        );
      }
    }
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds == 0) {
        t.cancel();
      } else {
        if (mounted) {
          setState(() {
            remainingSeconds--;
          });
        }
      }
    });
  }

  String formatTime(int seconds) {
    int min = seconds ~/ 60;
    int sec = seconds % 60;
    return "$min:${sec.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      extendBodyBehindAppBar: true,
      // AppBar removed for immersive "super duper modern" look
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('rides').doc(widget.rideId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2D3250)));
          }

          var ride = snapshot.data!.data() as Map<String, dynamic>;
          String userId = ride['userId'];
          LatLng pickupLocation = LatLng(ride['pickup']['lat'], ride['pickup']['lng']);

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
            builder: (context, userSnap) {
              String userPhone = "";
              String userName = "Rider";
              if (userSnap.hasData && userSnap.data!.exists) {
                userPhone = userSnap.data!['phone'] ?? "";
                userName = userSnap.data!['name'] ?? "Rider";
              }

              return Stack(
                children: [
                  // 🗺️ IMMERSIVE MAP SECTION
                  Positioned.fill(
                    bottom: MediaQuery.of(context).size.height * 0.4,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(target: pickupLocation, zoom: 16),
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      markers: {
                        Marker(
                          markerId: const MarkerId("pickup_point"),
                          position: pickupLocation,
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                        ),
                      },
                    ),
                  ),

                  // 📲 MODERN ACTION PANEL
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                      // 🔥 FIX: Captures clicks and prevents them from reaching the map
                      onTap: () {},
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.55,
                        padding: const EdgeInsets.fromLTRB(25, 35, 25, 25),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2D3250),
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                          boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, -10))],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // 🏁 TRIP OVERVIEW CARD
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 25,
                                      backgroundColor: Colors.white24,
                                      child: Icon(Icons.person, color: Colors.white),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(userName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                          Text("Pickup: ${ride['pickup']['address']}", 
                                            maxLines: 1, overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: userPhone.isNotEmpty ? () => _makePhoneCall(userPhone) : null,
                                      icon: const Icon(Icons.call_rounded, color: Colors.greenAccent),
                                      style: IconButton.styleFrom(backgroundColor: Colors.white12),
                                    )
                                  ],
                                ),
                              ),

                              const SizedBox(height: 25),

                              // ⏱️ PULSING TIMER SECTION
                              ScaleTransition(
                                scale: Tween(begin: 1.0, end: 1.05).animate(_pulseController),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.indigoAccent, Colors.blueAccent.shade700],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15)],
                                  ),
                                  child: Column(
                                    children: [
                                      const Text("ESTIMATED ARRIVAL", style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 5),
                                      Text(
                                        formatTime(remainingSeconds),
                                        style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 35),

                              // 🛠️ BOTTOM ACTIONS
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.redAccent,
                                        side: const BorderSide(color: Colors.redAccent, width: 2),
                                        padding: const EdgeInsets.symmetric(vertical: 18),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                      ),
                                      onPressed: () async {
                                        await FirebaseFirestore.instance.collection('rides').doc(widget.rideId).update({"status": "cancelled"});
                                        if (!mounted) return;
                                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DriverHome()), (route) => false);
                                      },
                                      child: const Text("Cancel Ride", style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(0xFF2D3250),
                                        padding: const EdgeInsets.symmetric(vertical: 18),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                        elevation: 5,
                                      ),
                                      onPressed: () async {
                                        await FirebaseFirestore.instance.collection('rides').doc(widget.rideId).update({"status": "arrived"});
                                        if (!context.mounted) return;
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => DriverOTPPage(rideId: widget.rideId)));
                                      },
                                      child: const Text("I've Arrived", style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}