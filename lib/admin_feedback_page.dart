import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminFeedbackPage extends StatefulWidget {
  const AdminFeedbackPage({super.key});

  @override
  State<AdminFeedbackPage> createState() => _AdminFeedbackPageState();
}

class _AdminFeedbackPageState extends State<AdminFeedbackPage> {
  String _filterRole = "All"; // All, user, driver

  Future<String> _getName(String id, String role) async {
    try {
      String collection = role.toLowerCase() == 'driver' ? 'drivers' : 'users';
      var doc = await FirebaseFirestore.instance.collection(collection).doc(id).get();
      return doc.data()?['name'] ?? "Unknown $role";
    } catch (e) {
      return "Deleted Account";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F9),
      appBar: AppBar(
        title: const Text("SENTIMENT ANALYSIS", 
          style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 14)),
        backgroundColor: const Color(0xFF2D3250),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 📊 ANALYTICS FILTER BAR
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: const BoxDecoration(
              color: Color(0xFF2D3250),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterChip("All"),
                _buildFilterChip("User"),
                _buildFilterChip("Driver"),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _filterRole == "All" 
                ? FirebaseFirestore.instance.collection('feedback').orderBy('createdAt', descending: true).snapshots()
                : FirebaseFirestore.instance.collection('feedback').where('fromRole', isEqualTo: _filterRole.toLowerCase()).orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Data Error: ${snapshot.error}"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF2D3250)));

                var feedbacks = snapshot.data!.docs;

                if (feedbacks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_graph_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
                        const SizedBox(height: 15),
                        const Text("No sentiments recorded yet", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: feedbacks.length,
                  itemBuilder: (context, index) {
                    var fb = feedbacks[index];
                    final data = fb.data() as Map<String, dynamic>;
                    double rating = (data['rating'] ?? 0).toDouble();
                    List<dynamic> tags = data['tags'] ?? [];
                    String category = data['vehicleCategory'] ?? "Standard";

                    return TweenAnimationBuilder(
                      duration: Duration(milliseconds: 400 + (index * 100)),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, double value, child) => Opacity(
                        opacity: value,
                        child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🌟 TOP SECTION: RATING & VEHICLE TYPE
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: List.generate(5, (star) => Icon(
                                          Icons.star_rounded, 
                                          color: star < rating ? Colors.amber : Colors.grey.shade200, 
                                          size: 18
                                        )),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(category.toUpperCase(), style: const TextStyle(color: Colors.cyan, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                    ],
                                  ),
                                  Text(
                                    data['createdAt'] != null 
                                      ? DateFormat('jm • d MMM').format((data['createdAt'] as Timestamp).toDate())
                                      : "",
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),

                            // 💬 TAGS CLOUD (The New Specific Feedback)
                            if (tags.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: tags.map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: rating >= 4 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: rating >= 4 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2)),
                                    ),
                                    child: Text(tag, style: TextStyle(
                                      color: rating >= 4 ? Colors.green.shade700 : Colors.red.shade700, 
                                      fontSize: 11, 
                                      fontWeight: FontWeight.bold
                                    )),
                                  )).toList(),
                                ),
                              ),

                            // 📝 WRITTEN COMMENT
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                data['comment'] != null && data['comment'].toString().isNotEmpty
                                    ? "\"${data['comment']}\""
                                    : "No text provided.",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: const Color(0xFF2D3250).withOpacity(0.7),
                                  height: 1.5,
                                ),
                              ),
                            ),

                            // 👤 FOOTER: SENDER / RECEIVER
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FD),
                                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                              ),
                              child: Row(
                                children: [
                                  _buildActorNode("From", data['fromId'], data['fromRole']),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                                  _buildActorNode("To", data['toId'], data['fromRole'] == "driver" ? "user" : "driver"),
                                ],
                              ),
                            ),
                          ],
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
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _filterRole == label;
    return GestureDetector(
      onTap: () => setState(() => _filterRole = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(
          color: isSelected ? Colors.black : Colors.white, 
          fontWeight: FontWeight.w900, 
          fontSize: 12
        )),
      ),
    );
  }

  Widget _buildActorNode(String label, String id, String role) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
          FutureBuilder<String>(
            future: _getName(id, role),
            builder: (context, snap) => Text(
              snap.data ?? "...",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2D3250)),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(role.toUpperCase(), style: TextStyle(color: role == "driver" ? Colors.blue : Colors.orange, fontSize: 8, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}