import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'driver_ride_page.dart';
import 'main.dart';
import 'dart:math';

class DriverOTPPage extends StatefulWidget {
  final String rideId;

  const DriverOTPPage({super.key, required this.rideId});

  @override
  State<DriverOTPPage> createState() => _DriverOTPPageState();
}

class _DriverOTPPageState extends State<DriverOTPPage> with SingleTickerProviderStateMixin {
  final otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode(); // 🔥 Added FocusNode
  String error = "";
  bool isLoading = false;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    
    otpController.addListener(() {
      setState(() {}); 
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    otpController.dispose();
    _focusNode.dispose(); // 🔥 Clean up
    super.dispose();
  }

  Future<void> verifyOTP() async {
    if (otpController.text.length < 4) {
      setState(() => error = "Please enter the full 4-digit code.");
      return;
    }

    setState(() {
      isLoading = true;
      error = "";
    });

    try {
      var rideSnap = await FirebaseFirestore.instance
          .collection('rides')
          .doc(widget.rideId)
          .get();

      if (!rideSnap.exists) throw "Ride not found";

      var rideData = rideSnap.data() as Map<String, dynamic>;
      String enteredOtp = otpController.text.trim();
      String correctOtp = "";

      if (rideData['pickup']['address'] == "Demo Pickup" &&
          rideData['drop']['address'] == "Demo Destination") {
        correctOtp = "1234";
      } else {
        correctOtp = rideData['otp'] ?? "";
      }

      if (enteredOtp == correctOtp && correctOtp.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('rides')
            .doc(widget.rideId)
            .update({"status": "ongoing"});

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DriverRidePage(rideId: widget.rideId)),
        );
      } else {
        _shakeController.forward(from: 0);
        setState(() => error = "Incorrect OTP. Access Denied.");
      }
    } catch (e) {
      setState(() => error = "System Error. Connection failed.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        title: const Text("AUTHENTICATION", 
          style: TextStyle(letterSpacing: 3, fontWeight: FontWeight.w900, fontSize: 14)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('rides').doc(widget.rideId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));

          var ride = snapshot.data!.data() as Map<String, dynamic>;
          bool isDemoRide = ride['pickup']['address'] == "Demo Pickup";

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                const SizedBox(height: 20),
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(seconds: 1),
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 2),
                            boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.2), blurRadius: 20)],
                          ),
                          child: const Icon(Icons.shield_rounded, color: Colors.cyanAccent, size: 50),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      _buildMiniRoute(Icons.radio_button_checked, Colors.greenAccent, ride['pickup']['address']),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: Colors.white10)),
                      _buildMiniRoute(Icons.location_on, Colors.redAccent, ride['drop']['address']),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // 🔢 SLEEK PIN INPUT BOX
                AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, child) {
                    final double offset = sin(_shakeController.value * pi * 4) * 8;
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: child,
                    );
                  },
                  child: Column(
                    children: [
                      const Text("INPUT RIDER PASSCODE", 
                        style: TextStyle(color: Colors.white54, letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 30),
                      
                      // 🔥 WRAPPED IN GESTURE DETECTOR TO ENSURE INPUT WORKS
                      GestureDetector(
                        onTap: () => _focusNode.requestFocus(),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Hidden TextField that remains tappable
                            SizedBox(
                              width: 300,
                              height: 70,
                              child: TextField(
                                controller: otpController,
                                focusNode: _focusNode,
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                autofocus: true,
                                cursorColor: Colors.transparent,
                                showCursor: false,
                                style: const TextStyle(color: Colors.transparent),
                                decoration: const InputDecoration(
                                  counterText: "",
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                              ),
                            ),
                            // Visual OTP Boxes
                            IgnorePointer( // 🔥 Allows taps to pass through to the TextField
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(4, (index) => _buildOTPBox(index)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),
                if (isDemoRide) const Text("DEMO ACTIVE: 1234", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                if (error.isNotEmpty) Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(error, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                ),

                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity,
                  height: 65,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 10,
                      shadowColor: Colors.cyanAccent.withOpacity(0.5),
                    ),
                    child: isLoading 
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text("INITIALIZE TRIP", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5)),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('rides').doc(widget.rideId).update({"status": "cancelled"});
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DriverHome()), (route) => false);
                  },
                  child: Text("ABORT MISSION", style: TextStyle(color: Colors.redAccent.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOTPBox(int index) {
    String text = otpController.text;
    bool isFocused = text.length == index;
    bool isFilled = text.length > index;
    String digit = isFilled ? text[index] : "";

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 60,
      height: 70,
      decoration: BoxDecoration(
        color: isFocused ? Colors.cyanAccent.withOpacity(0.05) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isFocused ? Colors.cyanAccent : (isFilled ? Colors.white24 : Colors.white10),
          width: isFocused ? 2 : 1,
        ),
        boxShadow: isFocused ? [BoxShadow(color: Colors.cyanAccent.withOpacity(0.1), blurRadius: 10)] : [],
      ),
      child: Center(
        child: Text(
          digit,
          style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMiniRoute(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 15),
        Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, 
          style: const TextStyle(color: Colors.white70, fontSize: 14))),
      ],
    );
  }
}