import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EmergencyPage extends StatefulWidget {
  final String? role; 
  
  const EmergencyPage({super.key, this.role});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? role;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.role != null) {
      role = widget.role;
      loading = false; 
    } else {
      fetchUserRole();
    }
  }

  Future<void> fetchUserRole() async {
    final user = _auth.currentUser;

    if (user == null) {
      setState(() {
        role = 'unknown';
        loading = false;
      });
      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        // ✅ Handles your exact DB structure: Admins & Users in the same collection
        String fetchedRole = userDoc.data()?['role']?.toString().toLowerCase() ?? '';
        if (fetchedRole == 'admin') {
          role = 'admin';
        } else {
          role = 'user'; // Defaults to user if it's not explicitly an admin
        }
      } else {
        final driverDoc = await _firestore.collection('drivers').doc(user.uid).get();
        
        if (driverDoc.exists) {
          role = driverDoc.data()?['role']?.toString().toLowerCase() ?? 'driver';
        } else {
          role = 'unknown';
        }
      }
    } catch (e) {
      role = 'unknown';
    }

    if (!mounted) return;
    setState(() {
      loading = false;
    });
  }

  Future<void> sendAlert(String type) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('emergencies').add({
      'userId': user.uid,
      'role': role ?? 'unknown',
      'type': type,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("$type alert sent! 🚨"),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 🛡️ Safe check
    String safeRole = (role ?? '').toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Emergency", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.red[800],
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: safeRole == 'user'
            ? userEmergencyUI()
            : safeRole == 'driver'
            ? driverEmergencyUI()
            : adminEmergencyUI(), // Admin UI acts as the fallback for 'admin'
      ),
    );
  }

  // ==========================================
  // USER UI
  // ==========================================
  Widget userEmergencyUI() {
    return Center( 
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600), 
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, 
          children: [
            const Text(
              "Quick Assistance",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3250)),),
            const SizedBox(height: 5),
            const Text(
              "Tap to notify help immediately",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 25),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 2.2, 
              children: [
                emergencyButton("Safety", Icons.shield_rounded, Colors.redAccent),
                emergencyButton("Medical", Icons.local_hospital_rounded, Colors.blueAccent),
                emergencyButton("Vehicle", Icons.minor_crash_rounded, Colors.orangeAccent),
                emergencyButton("General", Icons.help_center_rounded, Colors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget emergencyButton(String label, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15), 
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () => sendAlert(label),
          borderRadius: BorderRadius.circular(15),
          child: Row( 
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: color), 
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.bold, 
                      color: Color(0xFF2D3250),
                    ),
                  ),
                  const Text(
                    "Alert Now",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // DRIVER UI
  // ==========================================
  Widget driverEmergencyUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_rounded, size: 80, color: Colors.red[700]),
          ),
          const SizedBox(height: 25),
          const Text(
            "Driver Emergency Control",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3250)),
          ),
          const SizedBox(height: 10),
          const Text(
            "Triggering this will immediately alert the admin platform.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
              ),
              onPressed: () => sendAlert("Driver Emergency"),
              icon: const Icon(Icons.campaign),
              label: const Text("Trigger Emergency Alert", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2D3250),
                side: const BorderSide(color: Color(0xFF2D3250)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () {}, 
              icon: const Icon(Icons.phone),
              label: const Text("Call Emergency Services", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ADMIN UI
  // ==========================================
  Widget adminEmergencyUI() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.admin_panel_settings, size: 80, color: Colors.blue[700]),
            ),
            const SizedBox(height: 25),
            const Text(
              "Emergency Administration",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3250)),
            ),
            const SizedBox(height: 10),
            const Text(
              "Monitor and resolve active platform emergencies.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D3250),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EmergencyRequestsPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.list_alt),
                label: const Text("Manage Emergency Requests", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2D3250),
                  side: const BorderSide(color: Color(0xFF2D3250)),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh Dashboard", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 🚨 REAL-WORLD EMERGENCY REQUESTS PAGE
// ==========================================
class EmergencyRequestsPage extends StatelessWidget {
  const EmergencyRequestsPage({super.key});

  Future<Map<String, String>> _fetchPersonDetails(String userId, String role) async {
    String name = "Unknown";
    String phone = "N/A";

    if (userId.isEmpty) return {"name": name, "phone": phone};

    try {
      String collection = (role.toLowerCase() == 'driver') ? 'drivers' : 'users';
      var doc = await FirebaseFirestore.instance.collection(collection).doc(userId).get();
      
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        name = data['name'] ?? "Unknown";
        phone = data['phone'] ?? "N/A";
      }
    } catch (e) {
      debugPrint("Error fetching details: $e");
    }
    return {"name": name, "phone": phone};
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Emergency Requests", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: firestore
            .collection('emergencies')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green[300]),
                  const SizedBox(height: 15),
                  const Text("All Clear", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                  const Text("No active emergencies right now.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final emergencies = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: emergencies.length,
            itemBuilder: (context, index) {
              var doc = emergencies[index];
              var data = doc.data() as Map<String, dynamic>;
              
              bool isPending = data['status'] == 'pending';
              String role = data['role']?.toString().toUpperCase() ?? 'UNKNOWN';
              String type = data['type'] ?? 'General Alert';
              String userId = data['userId'] ?? '';

              String timeString = "Just now";
              if (data['timestamp'] != null) {
                DateTime date = (data['timestamp'] as Timestamp).toDate();
                timeString = DateFormat('dd MMM yyyy, hh:mm a').format(date);
              }

              return FutureBuilder<Map<String, String>>(
                future: _fetchPersonDetails(userId, data['role'] ?? 'user'),
                builder: (context, detailSnapshot) {
                  String name = "Loading...";
                  String phone = "Loading...";if (detailSnapshot.connectionState == ConnectionState.done && detailSnapshot.hasData) {
                    name = detailSnapshot.data!['name']!;
                    phone = detailSnapshot.data!['phone']!;
                  }

                  return Card(
                    elevation: isPending ? 4 : 1,
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(
                        color: isPending ? Colors.red : Colors.grey.shade300, 
                        width: isPending ? 2 : 1
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(isPending ? Icons.warning_rounded : Icons.check_circle, 
                                       color: isPending ? Colors.red : Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    type.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      color: isPending ? Colors.red : Colors.green, 
                                      fontSize: 14
                                    ),
                                  ),
                                ],
                              ),
                              Text(timeString, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 25),
                          
                          Row(
                            children: [
                              Icon(role == 'DRIVER' ? Icons.directions_car : Icons.person, color: Colors.blueGrey),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(name, 
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3250))
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(5)),
                                child: Text(role, style: TextStyle(fontSize: 10, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.phone, color: Colors.grey, size: 18),
                              const SizedBox(width: 10),
                              Text(phone, style: TextStyle(color: Colors.grey.shade700, fontSize: 15)),
                            ],
                          ),const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isPending ? Colors.green : Colors.grey.shade300,
                                foregroundColor: isPending ? Colors.white : Colors.grey.shade600,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: isPending ? () async {
                                await doc.reference.update({'status': 'handled'});
                              } : null,
                              child: Text(isPending ? "Mark as Handled / Safe" : "Incident Closed"),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                }
              );
            },
          );
        },
      ),
    );
  }
}