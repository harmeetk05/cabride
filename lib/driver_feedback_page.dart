import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';

class DriverFeedbackPage extends StatefulWidget {
  final String rideId;
  final String userId;

  const DriverFeedbackPage({super.key, required this.rideId, required this.userId});

  @override
  State<DriverFeedbackPage> createState() => _DriverFeedbackPageState();
}

class _DriverFeedbackPageState extends State<DriverFeedbackPage> {
  double rating = 5;
  final commentController = TextEditingController();
  List<String> selectedTags = [];

  final Map<String, IconData> goodTags = {
    "Polite Passenger": Icons.face_rounded,
    "Ready on Time": Icons.timer_rounded,
    "Helpful Location": Icons.location_on_rounded,
    "Friendly": Icons.chat_bubble_outline_rounded,
    "Safe Boarding": Icons.check_circle_outline_rounded,
  };

  final Map<String, IconData> badTags = {
    "Late for Pickup": Icons.hourglass_empty_rounded,
    "Rude Behavior": Icons.person_off_rounded,
    "Messy Passenger": Icons.layers_clear_rounded,
    "Wrong Drop Spot": Icons.wrong_location_rounded,
  };

  Future<void> submit() async {
    String driverId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('feedback').add({
      "rideId": widget.rideId,
      "fromId": driverId,
      "toId": widget.userId,
      "fromRole": "driver",
      "rating": rating,
      "tags": selectedTags, // 🔥 Storing as sub-array
      "comment": commentController.text,
      "createdAt": Timestamp.now(),
    });

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DriverHome()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    bool isGood = rating >= 4;
    Map<String, IconData> currentTagMap = isGood ? goodTags : badTags;

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark Mode
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          children: [
            const Icon(Icons.stars_rounded, size: 80, color: Colors.amber),
            const SizedBox(height: 20),
            const Text("How was the Passenger?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 40),
            
            // ⭐ STAR SELECTOR
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() {
                    rating = index + 1.0;
                    selectedTags.clear();
                  }),
                  child: Icon(
                    index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 50,
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 40),
            
            // 🏷️ SELECTABLE CHIPS
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: currentTagMap.keys.map((tag) {
                bool isSelected = selectedTags.contains(tag);
                return GestureDetector(
                  onTap: () => setState(() => isSelected ? selectedTags.remove(tag) : selectedTags.add(tag)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      // 🔥 COLOR CODING
                      color: isSelected 
                        ? (isGood ? Colors.green.shade600 : Colors.red.shade600)
                        : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected 
                          ? Colors.transparent 
                          : (isGood ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3))
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(currentTagMap[tag], size: 16, color: isSelected ? Colors.white : (isGood ? Colors.green : Colors.red)),
                        const SizedBox(width: 8),
                        Text(tag, style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70, 
                          fontWeight: FontWeight.bold,
                          fontSize: 13
                        )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),
            TextField(
              controller: commentController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "Add a note for Admin...",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text("SUBMIT & GO ONLINE", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }
}