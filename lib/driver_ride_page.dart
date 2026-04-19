import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'driver_pay_page.dart';
import 'EmergencyPage.dart';

class DriverRidePage extends StatefulWidget {
  final String rideId;

  const DriverRidePage({super.key, required this.rideId});

  @override
  State<DriverRidePage> createState() => _DriverRidePageState();
}

class _DriverRidePageState extends State<DriverRidePage> with SingleTickerProviderStateMixin {
  int remainingSeconds = 0;
  Timer? timer;
  bool _isEnding = false;
  bool _timerInitialized = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _startTimer() {
    if (timer != null) return;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds <= 0) {
        t.cancel();
      } else {
        if (mounted) {
          setState(() => remainingSeconds--);
        }
      }
    });
  }

  String formatTime(int s) =>
      "${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}";

  void openEmergency() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmergencyPage()),
    );
  }

  Future<void> showCompletionAnimation() async {
    if (!mounted) return;
    setState(() => _isEnding = true);

    OverlayEntry? entry;
    final scaffoldContext = context;

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
                  duration: const Duration(milliseconds: 800),
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
                          boxShadow: [BoxShadow(color: Colors.green, blurRadius: 40)],
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.black, size: 80),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                const Text(
                  "Destination Reached",
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, decoration: TextDecoration.none),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(scaffoldContext).insert(entry);
    await Future.delayed(const Duration(seconds: 2, milliseconds: 500));
    entry.remove();
  }

  Future<void> completeRide(Map<String, dynamic> rideData) async {
    if (_isEnding) return;
    await showCompletionAnimation();

    if (!mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(widget.rideId)
          .update({
        "status": "completed",
        "paymentStatus": "pending",
      });

      String driverId = rideData['driverId'];
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .update({"active": true});

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DriverPayPage(
            rideId: widget.rideId,
            userId: rideData['userId'],
            fare: rideData['fare'],
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error completing ride: $e");
      setState(() => _isEnding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to complete ride on server.")),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _isEnding,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FD),
        // AppBar removed for "super duper modern" look
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('rides')
              .doc(widget.rideId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF2D3250)));
            }

            var rideDoc = snapshot.data!;
            if (!rideDoc.exists) return const Center(child: Text("Ride data not found."));
            var data = rideDoc.data() as Map<String, dynamic>;

            if (!_timerInitialized) {
              double distance = (data['distance'] ?? 5.0).toDouble();
              double estimatedMinutes = (distance / 25) * 60;
              remainingSeconds = ((estimatedMinutes + 2) * 60).toInt();
              _timerInitialized = true;
              Future.delayed(Duration.zero, () => _startTimer());
            }

            bool warning = remainingSeconds < 120;
            LatLng pickup = LatLng(data['pickup']['lat'], data['pickup']['lng']);
            LatLng drop = LatLng(data['drop']['lat'], data['drop']['lng']);

            return Stack(
              children: [
                // 🗺️ IMMERSIVE MAP (Background Layer)
                Positioned.fill(
                  bottom: MediaQuery.of(context).size.height * 0.4,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(target: drop, zoom: 14),
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    markers: {
                      Marker(
                        markerId: const MarkerId("pickup"),
                        position: pickup,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                      ),
                      Marker(
                        markerId: const MarkerId("destination"),
                        position: drop,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      ),
                    },
                  ),
                ),

                // 📲 MODERN CONTROL PANEL (Interaction Layer)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: GestureDetector(
                    // 🔥 FIX: Blocks clicks and stops the "palm grab" cursor issue
                    onTap: () {},
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.55,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2D3250),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, -10))],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(25, 20, 25, 25),
                              child: Column(
                                children: [
                                  // ⏱️ PULSING TIME CARD
                                  FadeTransition(
                                    opacity: Tween(begin: 0.8, end: 1.0).animate(_pulseController),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
                                      decoration: BoxDecoration(
                                        color: warning ? Colors.redAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(color: warning ? Colors.redAccent : Colors.white12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("ESTIMATED ARRIVAL", style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 4),
                                              Text(formatTime(remainingSeconds), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                                            ],
                                          ),
                                          const Icon(Icons.timer_outlined, color: Colors.white60, size: 40),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 25),

                                  // 📍 ROUTE STEPPER CARD
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.03),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Column(
                                      children: [
                                        _buildRouteRow(data['pickup']['address'] ?? "Unknown", Colors.greenAccent, "Pickup"),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                          child: Align(alignment: Alignment.centerLeft, child: Container(width: 2, height: 20, color: Colors.white10)),
                                        ),
                                        _buildRouteRow(data['drop']['address'] ?? "Unknown", Colors.redAccent, "Destination"),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 35),

                                  // 🛠️ PRIMARY ACTIONS
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _modernButton(
                                          onTap: openEmergency,
                                          icon: Icons.shield_rounded,
                                          label: "Safety",
                                          color: Colors.redAccent.withOpacity(0.15),
                                          textColor: Colors.redAccent,
                                          isOutline: true,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: _modernButton(
                                          onTap: () => completeRide(data),
                                          icon: Icons.check_circle_rounded,
                                          label: "Complete",
                                          color: Colors.greenAccent,
                                          textColor: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  const Text("Please ensure passenger has safely alighted before completing.",
                                      textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRouteRow(String address, Color color, String label) {
    return Row(
      children: [
        Icon(Icons.radio_button_checked, color: color, size: 20),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Text(address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _modernButton({required VoidCallback onTap, required IconData icon, required String label, required Color color, required Color textColor, bool isOutline = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isOutline ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(20),
          border: isOutline ? Border.all(color: textColor, width: 2) : null,
          boxShadow: !isOutline ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}