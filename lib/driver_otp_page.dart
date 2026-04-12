import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'driver_ride_page.dart';

class DriverOTPPage extends StatefulWidget {
  final String rideId;

  const DriverOTPPage({super.key, required this.rideId});

  @override
  State<DriverOTPPage> createState() => _DriverOTPPageState();
}

class _DriverOTPPageState extends State<DriverOTPPage> {

  final otpController = TextEditingController();
  String error = "";
  bool isLoading = false;

  Future<void> verifyOTP() async {

    setState(() {
      isLoading = true;
      error = "";
    });

    try {
      var ride = await FirebaseFirestore.instance
          .collection('rides')
          .doc(widget.rideId)
          .get();

      String enteredOtp = otpController.text.trim();

      String correctOtp;

      // 🎯 DEMO MODE LOGIC
      if (ride['pickup'] == "Demo Pickup" &&
          ride['drop'] == "Demo Destination") {

        correctOtp = "1234";

      } else {
        // 🔒 REAL LOGIC
        String userId = ride['userId'];

        var user = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        correctOtp = user['otp'];
      }

      if (enteredOtp == correctOtp) {

        await FirebaseFirestore.instance
            .collection('rides')
            .doc(widget.rideId)
            .update({"status": "ongoing"});

        if (!context.mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DriverRidePage(rideId: widget.rideId),
          ),
        );

      } else {
        setState(() {
          error = "Incorrect OTP. Try again.";
        });
      }

    } catch (e) {
      setState(() {
        error = "Something went wrong";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text("Verify Rider"),
        backgroundColor: Colors.black,
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .doc(widget.rideId)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var ride = snapshot.data!;

          bool isDemoRide =
              ride['pickup'] == "Demo Pickup" &&
              ride['drop'] == "Demo Destination";

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                // 🚗 RIDE INFO CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text("Pickup",
                          style: TextStyle(color: Colors.grey)),

                      const SizedBox(height: 6),

                      Text(
                        ride['pickup'],
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Drop: ${ride['drop']}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 🔐 OTP CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [

                      const Icon(Icons.lock,
                          color: Colors.white, size: 30),

                      const SizedBox(height: 10),

                      const Text(
                        "Enter Rider OTP",
                        style: TextStyle(color: Colors.white70),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          letterSpacing: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: "••••",
                          hintStyle:
                              const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      // 🎯 DEMO HINT
                      if (isDemoRide) ...[
                        const SizedBox(height: 15),
                        const Text(
                          "Demo OTP: 1234",
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (error.isNotEmpty)
                  Text(error,
                      style: const TextStyle(color: Colors.red)),

                const Spacer(),

                // 🚀 VERIFY BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: isLoading ? null : verifyOTP,
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : const Text(
                            "Start Ride",
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Ask rider for OTP before starting trip",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}