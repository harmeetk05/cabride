import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  _EmergencyPageState createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? role; // 'user', 'driver', 'admin'

  @override
  void initState() {
    super.initState();
    fetchUserRole();
  }

  // Fetch role from Firestore based on current user
  void fetchUserRole() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // 1️⃣ Try users collection
  final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  if (userDoc.exists) {
    setState(() {
      role = userDoc['role']; // 'user' or 'admin'
    });
    return;
  }

  // 2️⃣ Try drivers collection
  final driverDoc = await FirebaseFirestore.instance.collection('drivers').doc(user.uid).get();
  if (driverDoc.exists) {
    setState(() {
      role = driverDoc['role']; // should be 'driver'
    });
    return;
  }

  // 3️⃣ If not found anywhere
  setState(() {
    role = 'unknown';
  });
  print('Error: User not found in users or drivers collection!');
}
  // Send emergency alert
  void sendEmergencyAlert() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('emergencies').add({
      'userId': user.uid,
      'role': role,
      'timestamp': DateTime.now(),
      'status': 'pending',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Emergency alert sent! 🚨")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (role == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Emergency")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Emergency Module"),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: role == 'user'
            ? userEmergencyUI()
            : role == 'driver'
                ? driverEmergencyUI()
                : adminEmergencyUI(),
      ),
    );
  }

  // UI for regular users
  Widget userEmergencyUI() {
    return Column(
  children: [
    // Safety
    Icon(Icons.warning, size: 50, color: Colors.red),
    Text('Safety', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    ElevatedButton(
      onPressed: () async {
         final user = FirebaseAuth.instance.currentUser;
    final userId = FirebaseAuth.instance.currentUser!.uid; // fixes the red line
  await FirebaseFirestore.instance.collection('emergencies').add({
    'role': role, // pass this from your homepage: 'driver', 'user', or 'admin'
    'type': 'Safety alert triggered', // change for each button
    'timestamp': FieldValue.serverTimestamp(),
    'status': 'pending',
    'userId': userId, // if you have the logged-in user's ID
  });

  // Optional: show confirmation
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Alert sent!')),
  );
},
      child: Text('Send Alert'),
    ),
    SizedBox(height: 20),

    // Medical
    Icon(Icons.medical_services, size: 50, color: Colors.blue),
    Text('Medical', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    ElevatedButton(
  onPressed: () async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = FirebaseAuth.instance.currentUser!.uid; // fixes the red line

    await FirebaseFirestore.instance.collection('emergencies').add({
      'role': role,
      'type': 'Medical',
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      'userId': userId,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Medical alert sent!')),
    );
  },
  child: Text('Send Alert'),
),

  
    SizedBox(height: 20),

    // Vehicle
    Icon(Icons.car_crash, size: 50, color: Colors.orange),
    Text('Vehicle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    ElevatedButton(
onPressed: () async {
   final user = FirebaseAuth.instance.currentUser;
    final userId = FirebaseAuth.instance.currentUser!.uid; // fixes the red line
  await FirebaseFirestore.instance.collection('emergencies').add({
    'role': role, // pass this from your homepage: 'driver', 'user', or 'admin'
    'type': 'Vehicle alert triggered', // change for each button
    'timestamp': FieldValue.serverTimestamp(),
    'status': 'pending',
    'userId': userId, // if you have the logged-in user's ID
  });

  // Optional: show confirmation
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Alert sent!')),
  );
},      child: Text('Send Alert'),
    ),
    SizedBox(height: 20),

    // Other
    Icon(Icons.report_problem, size: 50, color: Colors.green),
    Text('Other', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    ElevatedButton(
onPressed: () async {
   final user = FirebaseAuth.instance.currentUser;
    final userId = FirebaseAuth.instance.currentUser!.uid; // fixes the red line
  await FirebaseFirestore.instance.collection('emergencies').add({
    'role': role, // pass this from your homepage: 'driver', 'user', or 'admin'
    'type': 'Other alert triggered', // change for each button
    'timestamp': FieldValue.serverTimestamp(),
    'status': 'pending',
    'userId': userId, // if you have the logged-in user's ID
  });

  // Optional: show confirmation
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Alert sent!')),
  );
},      child: Text('Send Alert'),
    ),
  ],
);
  }

  // UI for drivers
  Widget driverEmergencyUI() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [

      Icon(Icons.warning, size: 80, color: Colors.red),
      SizedBox(height: 20),

      Text(
        "Emergency Control Panel",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),

      SizedBox(height: 30),

      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        ),
        onPressed: () async {
  await FirebaseFirestore.instance.collection('emergencies').add({
    'userId': FirebaseAuth.instance.currentUser!.uid,
    'role': 'driver',
    'status': 'pending',
    'timestamp': FieldValue.serverTimestamp(),
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Emergency Alert Sent")),
  );
},
        child: Text("Trigger Emergency Alert"),
      ),

      SizedBox(height: 20),

      ElevatedButton(
        onPressed: () {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Calling Emergency Services...")),
  );
},
        child: Text("Call Emergency Services"),
      ),

    ],
  );
}
  // UI for admins
  Widget adminEmergencyUI() {
  return Scaffold(
    body: Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              // Top Icon
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  size: 80,
                  color: Colors.blue,
                ),
              ),

              SizedBox(height: 30),

              // Title
              Text(
                "Emergency Administration",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 10),

              Text(
                "Monitor and manage all emergency alerts in real-time.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 40),

              // Manage Requests Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.list_alt),
                  label: Text("Manage Emergency Requests"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmergencyRequestsPage(),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 20),

              // Refresh Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: Icon(Icons.refresh),
                  label: Text("Refresh Dashboard"),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Dashboard refreshed"),
                      ),
                    );
                  },
                ),
              ),

            ],
          ),
        ),
      ),
    ),
  );
}}

// This page shows emergency requests (for drivers/admin)
class EmergencyRequestsPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  const EmergencyRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Emergency Requests")),
      body: StreamBuilder(
        stream: _firestore.collection('emergencies').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) { return Center(child: CircularProgressIndicator());}

          final emergencies = snapshot.data!.docs;

          if (emergencies.isEmpty) return Center(child: Text("No emergencies yet."));

          return ListView.builder(
            itemCount: emergencies.length,
            itemBuilder: (context, index) {
              var emergencyDoc = emergencies[index];
              var emergency = emergencyDoc.data();
              return ListTile(
                leading: Icon(Icons.warning, color: Colors.red),
                title: Text("User ID: ${emergency['userId']}"),
                subtitle: Text("Role: ${emergency['role']} | Status: ${emergency['status']}"),
                trailing: emergency['status'] == 'pending'
                    ? ElevatedButton(
                        onPressed: () async {
                          await emergencyDoc.reference.update({'status': 'handled'});
                        },
                        child: Text("Mark as Handled"),
                      )
                    : Text("Handled", style: TextStyle(color: Colors.green)),
              );
            },
          );
        },
      ),
    );
  }
}