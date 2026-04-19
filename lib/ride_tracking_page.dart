import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔥 Added for current user ID
import 'user_payment_page.dart';
import 'EmergencyPage.dart';
import 'main.dart';

class RideTrackingPage extends StatefulWidget {
  final String rideId;

  const RideTrackingPage({super.key, required this.rideId});

  @override
  State<RideTrackingPage> createState() => _RideTrackingPageState();
}

class _RideTrackingPageState extends State<RideTrackingPage> with SingleTickerProviderStateMixin {
  bool _isEnding = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  // 🔥 NEW: Share Trip Logic
  Future<void> _shareTripDetails(Map<String, dynamic> ride, Map<String, dynamic> driver) async {
    try {
      String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      String emergencyContact = userDoc.data()?['emergencyContact'] ?? "";

      if (emergencyContact.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No emergency contact found in your profile!")),
          );
        }
        return;
      }

      String message = "I am on a ride with CabRide!\n"
          "Driver: ${driver['name']}\n"
          "From: ${ride['pickup']['address']}\n"
          "To: ${ride['drop']['address']}\n"
          "Track me using ride ID: ${widget.rideId}";

      final Uri smsUri = Uri(
        scheme: 'sms',
        path: emergencyContact,
        queryParameters: <String, String>{'body': message},
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
    } catch (e) {
      debugPrint("Error sharing trip: $e");
    }
  }

  void openEmergency(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyPage()));
  }

  void showCompletionOverlay() async {
    if (_isEnding) return;
    if (!mounted) return;
    setState(() => _isEnding = true);
    final scaffoldContext = context;
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Container(
          color: Colors.black.withOpacity(0.9),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 1000),
                  tween: Tween<double>(begin: 0, end: 1),
                  curve: Curves.elasticOut,
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.green, blurRadius: 30)],
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.black, size: 80),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                const Text("Arrived Safely!",
                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(scaffoldContext).insert(entry);
    await Future.delayed(const Duration(seconds: 3));
    entry.remove();
    if (!mounted) return;
    Navigator.pushReplacement(
        scaffoldContext, MaterialPageRoute(builder: (_) => UserPaymentPage(rideId: widget.rideId)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('rides').doc(widget.rideId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF2D3250)));
          if (!snapshot.data!.exists) return const Center(child: Text("Ride data not found."));

          var ride = snapshot.data!.data() as Map<String, dynamic>;
          LatLng p1 = LatLng(ride['pickup']['lat'], ride['pickup']['lng']);
          LatLng p2 = LatLng(ride['drop']['lat'], ride['drop']['lng']);

          if (ride['status'] == 'cancelled' && !_isEnding) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushAndRemoveUntil(
                  context, MaterialPageRoute(builder: (_) => const UserHome()), (route) => false);
            });
          }
          if (ride['status'] == 'completed' && !_isEnding) {
            WidgetsBinding.instance.addPostFrameCallback((_) => showCompletionOverlay());
          }

          return Stack(
            children: [
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: p1, zoom: 14),
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  markers: {
                    Marker(
                      markerId: const MarkerId("pickup"),
                      position: p1,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                    ),
                    Marker(
                      markerId: const MarkerId("drop"),
                      position: p2,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    ),
                  },
                ),
              ),

              Align(
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  onTap: () {}, 
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2D3250),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                      boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, -10))],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(30, 30, 30, 40),
                      child: ride['driverId'] == null
                          ? _buildSearchingUI()
                          : _buildDriverDetails(ride),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchingUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(1 - _pulseController.value), width: 4),
              ),
              child: const Icon(Icons.radar_rounded, color: Colors.white, size: 50),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text("Dispatching Captain...", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildDriverDetails(Map<String, dynamic> ride) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('drivers').doc(ride['driverId']).get(),
      builder: (context, driverSnap) {
        if (!driverSnap.hasData) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Colors.white)));
        var driverData = driverSnap.data!.data() as Map<String, dynamic>;
        
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('vehicles').doc(ride['driverId']).get(),
          builder: (context, vehicleSnap) {
            Map<String, dynamic> vehicle = vehicleSnap.hasData ? (vehicleSnap.data!.data() as Map<String, dynamic>? ?? {}) : {};

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white24,
                          backgroundImage: (driverData['imageUrl']?.isNotEmpty ?? false) ? NetworkImage(driverData['imageUrl']) : null,
                          child: (driverData['imageUrl']?.isEmpty ?? true) ? const Icon(Icons.person, color: Colors.white) : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                            child: Text((driverData['rating']?['rating'] ?? 0.0).toStringAsFixed(1), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(driverData['name'] ?? "Captain", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          Text("${vehicle['model'] ?? 'Car'} • ${vehicle['number'] ?? 'N/A'}", style: const TextStyle(color: Colors.white60)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
                      child: Text(ride['otp'] ?? "----", style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    )
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    // Call Button
                    _smallActionButton(
                      onTap: () => _makePhoneCall(driverData['phone'] ?? ""),
                      icon: Icons.call_rounded,
                      color: Colors.white10,
                      iconColor: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    // 🔥 Share Trip Button
                    Expanded(
                      child: _actionButton(
                        onTap: () => _shareTripDetails(ride, driverData),
                        icon: Icons.ios_share_rounded,
                        label: "Share Trip",
                        color: Colors.cyanAccent,
                        textColor: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Safety Button
                    Expanded(
                      child: _actionButton(
                        onTap: () => openEmergency(context),
                        icon: Icons.shield_rounded,
                        label: "Safety",
                        color: Colors.redAccent.withOpacity(0.2),
                        textColor: Colors.redAccent,
                        isOutline: true,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _smallActionButton({required VoidCallback onTap, required IconData icon, required Color color, required Color iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }

  Widget _actionButton({required VoidCallback onTap, required IconData icon, required String label, required Color color, required Color textColor, bool isOutline = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isOutline ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(20),
          border: isOutline ? Border.all(color: textColor, width: 2) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}