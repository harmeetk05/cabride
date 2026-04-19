import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';

class UserFeedbackPage extends StatefulWidget {
  final String rideId;
  final String driverId;

  const UserFeedbackPage({super.key, required this.rideId, required this.driverId});

  @override
  State<UserFeedbackPage> createState() => _UserFeedbackPageState();
}

class _UserFeedbackPageState extends State<UserFeedbackPage> {
  double rating = 5.0;
  final commentController = TextEditingController();
  bool isSubmitting = false;
  List<String> selectedTags = [];
  String vehicleCategory = "Standard"; // Default

  @override
  void initState() {
    super.initState();
    _fetchRideDetails();
  }

  // 🔥 Fetches ride category to show specific tags
  Future<void> _fetchRideDetails() async {
    var doc = await FirebaseFirestore.instance.collection('rides').doc(widget.rideId).get();
    if (doc.exists && mounted) {
      setState(() {
        vehicleCategory = doc.data()?['vehicle'] ?? "Standard";
      });
    }
  }

  // 🔥 Categorized Tags based on requirements
  Map<String, IconData> _getAvailableTags(bool isGood) {
    // Common Base Tags
    Map<String, IconData> tags = isGood 
      ? {"Polite Driver": Icons.face_retouching_natural, "Clean Car": Icons.auto_awesome, "Safe Driving": Icons.shield_rounded}
      : {"Rash Driving": Icons.speed, "Unclean Vehicle": Icons.dirty_lens, "Rude Behavior": Icons.person_off};

    // Category Specific additions
    if (vehicleCategory == "Junior") {
      isGood ? tags["Pristine Baby Seat"] = Icons.child_care : tags["No Baby Seat"] = Icons.child_friendly;
    } else if (vehicleCategory == "Senior XL") {
      isGood ? tags["Helpful with Walker"] = Icons.accessible : tags["Steep Step"] = Icons.height;
    } else if (vehicleCategory == "Comfort") {
      isGood ? tags["Great AC"] = Icons.ac_unit : tags["Noisy Cabin"] = Icons.volume_up;
    }

    return tags;
  }

  Future<void> submitFeedback() async {
    if (isSubmitting) return;
    setState(() => isSubmitting = true);
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference driverRef = FirebaseFirestore.instance.collection('drivers').doc(widget.driverId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot driverSnap = await transaction.get(driverRef);
        if (!driverSnap.exists) throw Exception("Driver not found!");

        Map<String, dynamic> driverData = driverSnap.data() as Map<String, dynamic>;
        Map<String, dynamic> ratingData = driverData['rating'] ?? {"rating": 0.0, "totalTrips": 0};
        
        double currentAvg = (ratingData['rating'] as num).toDouble();
        int currentTrips = (ratingData['totalTrips'] as num).toInt();
        int newTotalTrips = currentTrips + 1;
        double newAvg = ((currentAvg * currentTrips) + rating) / newTotalTrips;

        DocumentReference feedbackRef = FirebaseFirestore.instance.collection('feedback').doc();
        transaction.set(feedbackRef, {
          "rideId": widget.rideId,
          "fromId": userId,
          "toId": widget.driverId,
          "fromRole": "user",
          "rating": rating,
          "vehicleCategory": vehicleCategory, // 🔥 Log category for admin analytics
          "tags": selectedTags,
          "comment": commentController.text.trim(),
          "createdAt": FieldValue.serverTimestamp(),
        });

        transaction.update(driverRef, {
          "rating": {
            "rating": double.parse(newAvg.toStringAsFixed(1)),
            "totalTrips": newTotalTrips,
          }
        });
      });

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const UserHome()), (route) => false);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isGood = rating >= 4;
    Map<String, IconData> currentTagMap = _getAvailableTags(isGood);

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A), // Modern Midnight Dark
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
        child: Column(
          children: [
            const Text("How was your trip?", 
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
            const SizedBox(height: 8),
            Text("Category: $vehicleCategory", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 50),
            
            // ⭐ CUSTOM STAR SELECTOR WITH GLOW
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                bool active = index < rating;
                return GestureDetector(
                  onTap: () => setState(() {
                    rating = index + 1.0;
                    selectedTags.clear();
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(
                      active ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: active ? Colors.amberAccent : Colors.white10,
                      size: 55,
                      shadows: active ? [const Shadow(color: Colors.amber, blurRadius: 15)] : [],
                    ),
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 50),
            Text(isGood ? "HIGHLIGHTS" : "WHAT WENT WRONG?", 
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2, color: Colors.white38)),
            const SizedBox(height: 25),

            // 🏷️ DYNAMIC FILTER CHIPS
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: currentTagMap.keys.map((tag) {
                bool isSelected = selectedTags.contains(tag);
                Color themeColor = isGood ? Colors.greenAccent : Colors.redAccent;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedTags.remove(tag);
                      } else {
                        selectedTags.add(tag);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? themeColor : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isSelected ? themeColor : themeColor.withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: isSelected ? [BoxShadow(color: themeColor.withOpacity(0.3), blurRadius: 8)] : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          currentTagMap[tag], 
                          size: 16, 
                          color: isSelected ? Colors.black : themeColor
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tag,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),
            TextField(
              controller: commentController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Add a note...",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              height: 65,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 10,
                  shadowColor: Colors.cyanAccent.withOpacity(0.4),
                ),
                onPressed: isSubmitting ? null : submitFeedback,
                child: isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.black) 
                  : const Text("FINISH REVIEW", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ),
            )
          ],
        ),
      ),
    );
  }
}