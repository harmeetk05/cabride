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

    final userDoc =
        await _firestore.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      role = userDoc.data()?['role'];
    } else {
      final driverDoc =
          await _firestore.collection('drivers').doc(user.uid).get();

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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$type alert sent! 🚨")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency"),
        backgroundColor: Colors.red,
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

  // USER UI
  Widget userEmergencyUI() {
    return Column(
      children: [
        emergencyButton("Safety", Icons.warning, Colors.red),
        emergencyButton("Medical", Icons.medical_services, Colors.blue),
        emergencyButton("Vehicle", Icons.car_crash, Colors.orange),
        emergencyButton("Other", Icons.report_problem, Colors.green),
      ],
    );
  }

  Widget emergencyButton(String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 50, color: color),
        Text(label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ElevatedButton(
          onPressed: () => sendAlert(label),
          child: const Text("Send Alert"),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // DRIVER UI
  Widget driverEmergencyUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.warning, size: 80, color: Colors.red),
        const SizedBox(height: 20),
        const Text(
          "Emergency Control Panel",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),

        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => sendAlert("Driver Emergency"),
          child: const Text("Trigger Emergency Alert"),
        ),

        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: () {},
          child: const Text("Call Emergency Services"),
        ),
      ],
    );
  }

  // ADMIN UI
  Widget adminEmergencyUI() {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Icon(Icons.admin_panel_settings,
                  size: 80, color: Colors.blue),
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
                onPressed: () {
                  setState(() {});
                },
                child: const Text("Refresh Dashboard"),
              ),
            ],
          ),
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
                    "Role: ${data['role'] ?? ''} | Status: ${data['status'] ?? ''}"),
                trailing: data['status'] == 'pending'
                    ? ElevatedButton(
                        onPressed: () async {
                          await doc.reference
                              .update({'status': 'handled'});
                        },
                        child: const Text("Handled"),
                      )
                    : const Text("Done",
                        style: TextStyle(color: Colors.green)),
              );
            },
          );
        },
      ),
    );
  }
}