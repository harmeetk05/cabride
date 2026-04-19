import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ride_tracking_page.dart';

class RideSearchingPage extends StatefulWidget {
  final String rideId;

  const RideSearchingPage({super.key, required this.rideId});

  @override
  State<RideSearchingPage> createState() => _RideSearchingPageState();
}

class _RideSearchingPageState extends State<RideSearchingPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _startListening();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startListening() {
    FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        String status = snapshot.get('status');
        if (status == 'assigned') {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => RideTrackingPage(rideId: widget.rideId),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Finding Ride", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3250),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFFF8F9FD), Colors.white.withOpacity(0.8)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🚗 COMPACT RADAR ANIMATION (Fixed Size to prevent text movement)
            SizedBox(
              height: 200,
              width: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse Rings
                  ...List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        double progress = (_controller.value + (index / 3)) % 1.0;
                        return Container(
                          width: progress * 200, // Reduced from 300
                          height: progress * 200, // Reduced from 300
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF2D3250).withOpacity(1 - progress),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                  // Central Car Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D3250),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2D3250).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: const Icon(Icons.directions_car_filled_rounded, color: Colors.white, size: 40),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 50),
            
            const Text(
              "Searching for Captains",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF2D3250)),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Sit tight! We're matching you with the best driver for your route.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.5),
              ),
            ),
            
            const SizedBox(height: 70),
            
            // ❌ MODERN CANCEL BUTTON
            GestureDetector(
              onTap: () async {
                await FirebaseFirestore.instance
                    .collection('rides')
                    .doc(widget.rideId)
                    .update({"status": "cancelled"});
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                ),
                child: const Text(
                  "Cancel Request",
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}