import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

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
    fetchUserRole();
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

    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      role = userDoc.data()?['role'];
    } else {
      final driverDoc = await _firestore
          .collection('drivers')
          .doc(user.uid)
          .get();
      if (driverDoc.exists) {
        role = driverDoc.data()?['role'];
      } else {
        role = 'unknown';
      }
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("$type alert sent! 🚨")));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency"),
        backgroundColor: Colors.red,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: role == 'user'
            ? userEmergencyUI()
            : role == 'driver'
            ? driverEmergencyUI()
            : adminEmergencyUI(),
      ),
    );
  }

  // USER UI - Updated to Grid Layout
  Widget userEmergencyUI() {
  return Center( // ✅ Keeps the grid from stretching too wide on Web
    child: Container(
      constraints: const BoxConstraints(maxWidth: 600), // ✅ Limits width for a "Mobile" feel on Web
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // ✅ Only takes up necessary space
        children: [
          const Text(
            "Quick Assistance",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3250)),
          ),
          const Text(
            "Tap to notify help immediately",
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2, // ✅ CHANGED: This makes the tiles short rectangles!
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
      borderRadius: BorderRadius.circular(18), // Slightly less round for rectangles
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      child: InkWell(
        onTap: () => sendAlert(label),
        borderRadius: BorderRadius.circular(18),
        child: Row( // ✅ CHANGED: Using Row instead of Column for a side-by-side look
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color), // Smaller icon
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15, 
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
  // DRIVER UI - Properly Centered
  Widget driverEmergencyUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.warning, size: 80, color: Colors.red),
          const SizedBox(height: 20),
          const Text(
            "Emergency Control Panel",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => sendAlert("Driver Emergency"),
              child: const Text("Trigger Emergency Alert"),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {}, // Add calling logic here if needed
              child: const Text("Call Emergency Services"),
            ),
          ),
        ],
      ),
    );
  }

  // ADMIN UI
  Widget adminEmergencyUI() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.admin_panel_settings,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              "Emergency Administration",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EmergencyRequestsPage(),
                  ),
                );
              },
              child: const Text("Manage Emergency Requests"),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => setState(() {}),
              child: const Text("Refresh Dashboard"),
            ),
          ],
        ),
      ),
    );
  }
}

// EMERGENCY REQUEST PAGE
class EmergencyRequestsPage extends StatelessWidget {
  const EmergencyRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text("Emergency Requests")),
      body: StreamBuilder(
        stream: firestore
            .collection('emergencies')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final emergencies = snapshot.data!.docs;
          if (emergencies.isEmpty) {
            return const Center(child: Text("No emergencies yet."));
          }

          return ListView.builder(
            itemCount: emergencies.length,
            itemBuilder: (context, index) {
              var doc = emergencies[index];
              var data = doc.data();

              return ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: Text("User ID: ${data['userId'] ?? ''}"),
                subtitle: Text(
                  "Role: ${data['role'] ?? ''} | Status: ${data['status'] ?? ''}",
                ),
                trailing: data['status'] == 'pending'
                    ? ElevatedButton(
                        onPressed: () async {
                          await doc.reference.update({'status': 'handled'});
                        },
                        child: const Text("Handled"),
                      )
                    : const Text("Done", style: TextStyle(color: Colors.green)),
              );
            },
          );
        },
      ),
    );
  }
}
