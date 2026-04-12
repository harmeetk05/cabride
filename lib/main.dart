import 'dart:convert';
import 'package:cabride/admin_payment_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'driver_signup_page.dart';
import 'EmergencyPage.dart';
import 'package:cabride/payment_logs_page.dart';
import 'package:cabride/manage_users_page.dart';
import 'package:cabride/manage_drivers_page.dart';
import 'package:cabride/view_reports_page.dart';
import 'user_payment_page.dart';
import 'ride_vehicle_page.dart';
import 'driver_requests_page.dart';
import 'driver_payment_page.dart';
import 'admin_feedback_page.dart';
import 'admin_rides_dashboard.dart';
import 'admin_payment_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool isLoggedIn = false;
  String? role;

  @override
  void initState() {
    super.initState();
    checkSession();
  }

  Future<void> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool("isLoggedIn") ?? false;
      role = prefs.getString("role");
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) return LoginPage();

    if (role == "driver") return const DriverHome();
    if (role == "admin") return const AdminHome();
    return const UserHome();
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> loginUser() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      String uid = userCredential.user!.uid;

      // 🔎 Check USERS collection
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        String role = userDoc['role'];

        if (role == "user") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => UserHome()),
          );
          return;
        }
      }
      if (userDoc.exists) {
        String role = userDoc['role'];

        if (role == "admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AdminHome()),
          );
          return;
        }
      }

      // 🔎 Check DRIVERS collection
      DocumentSnapshot driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(uid)
          .get();

      if (driverDoc.exists) {
        String role = driverDoc['role'];

        if (role == "driver") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => DriverHome()),
          );
          return;
        }
      }

      // 🔎 Check ADMINS collection
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Role not found")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const SizedBox(height: 60),
            const Text(
              "CabRide",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: loginUser, child: const Text("Login")),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPassword()),
              ),
              child: const Text("Forgot Password?"),
            ),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Sign Up",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (context) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 10),

                            const Text(
                              "Choose Account Type",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 20),

                            ListTile(
                              leading: const Icon(Icons.person, size: 28),
                              title: const Text("Sign up as User"),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SignupPage(),
                                  ),
                                );
                              },
                            ),

                            const Divider(),

                            ListTile(
                              leading: const Icon(
                                Icons.directions_car,
                                size: 28,
                              ),
                              title: const Text("Sign up as Driver"),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DriverSignupPage(),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController emailController = TextEditingController();

  Future<void> resetPassword() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter your email")));
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Reset link sent to email")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    Navigator.pop(context);
  }

  void show(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: resetPassword,
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }
}

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {

  final pickupController = TextEditingController();
  final dropController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            children: [
              const SizedBox(height: 20),

              const Text(
                "Go anywhere with",
                style: TextStyle(fontSize: 28),
              ),
              const Text(
                "CabRide",
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              // 🚗 RIDE CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                child: Column(
                  children: [

                    // 📍 PICKUP
                    Row(
                      children: [
                        const Icon(Icons.radio_button_checked, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: pickupController,
                            decoration: const InputDecoration(
                              hintText: "Pickup location",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(),

                    // 📍 DROP
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: dropController,
                            decoration: const InputDecoration(
                              hintText: "Drop location",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 🚀 BUTTON FIXED HERE
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                        ),
                        onPressed: () {

                          String pickup = pickupController.text.trim();
                          String drop = dropController.text.trim();

                          if (pickup.isEmpty || drop.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Enter pickup & drop")),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RideVehiclePage(
                                pickup: pickup,
                                drop: drop,
                              ),
                            ),
                          );
                        },
                        child: const Text("See Prices"),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                "Quick Actions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EmergencyPage(),
                          ),
                        );
                      },
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            "Emergency",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserPaymentPage(),
                          ),
                        );
                      },
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            "Payments",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class DriverHome extends StatelessWidget {
  const DriverHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            children: [
              const SizedBox(height: 20),

              const Text(
                "Driver Dashboard",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              // Availability Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "You are Online",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Icon(Icons.toggle_on, size: 40, color: Colors.green),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Today's Overview",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(child: _driverStatCard("Rides", "8", Colors.blue)),
                  const SizedBox(width: 15),
                  Expanded(
  child: GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const DriverPaymentsPage(),
        ),
      );
    },
    child: _driverStatCard(
      "Earnings",
      "₹1450",
      Colors.orange,
    ),
  ),
),
                ],
              ),

              const SizedBox(height: 40),

              const Text(
                "Quick Actions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _actionCard(
                      title: "New Requests",
                      color: Colors.black,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                          builder: (_) => const DriverRequestsPage(),
                      ),
                    );
                   },
                  ),
                 ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _actionCard(
                      title: "Emergency",
                      color: Colors.red,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => EmergencyPage()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _driverStatCard(String title, String value, Color color) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _actionCard({
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  Stream<int> countStream(String collection) {
    return FirebaseFirestore.instance.collection(collection).snapshots().map(
          (snap) => snap.docs.length,
        );
  }

  Stream<double> revenueStream() {
    return FirebaseFirestore.instance
        .collection('rides')
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snap) {
      double total = 0;
      for (var d in snap.docs) {
        final data = d.data();
        final fare = data['fare'];

        if (fare is num) total += fare.toDouble();
        if (fare is String) total += double.tryParse(fare) ?? 0;
      }
      return total;
    });
  }

  Stream<int> activeRidesStream() {
    return FirebaseFirestore.instance
        .collection('rides')
        .where('status', whereIn: ['searching', 'assigned', 'ongoing'])
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            children: [
              const SizedBox(height: 20),
              const Text(
                "Admin Control Center",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 25),

              StreamBuilder(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, userSnap) {
                  return StreamBuilder(
                    stream: FirebaseFirestore.instance.collection('drivers').snapshots(),
                    builder: (context, driverSnap) {
                      return StreamBuilder(
                        stream: activeRidesStream(),
                        builder: (context, rideSnap) {
                          return StreamBuilder(
                            stream: revenueStream(),
                            builder: (context, revenueSnap) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _adminStatCard(
                                          "Users",
                                          "${userSnap.data?.docs.length ?? 0}",
                                          Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _adminStatCard(
                                          "Drivers",
                                          "${driverSnap.data?.docs.length ?? 0}",
                                          Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: _adminStatCard(
                                          "Active Rides",
                                          "${rideSnap.data ?? 0}",
                                          Colors.orange,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _adminStatCard(
                                          "Revenue",
                                          "₹${(revenueSnap.data ?? 0).toStringAsFixed(0)}",
                                          Colors.purple,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 30),

              const Text(
                "Management",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              _managementTile(context, "Manage Users"),
              _managementTile(context, "Manage Drivers"),
              _managementTile(context, "Rides Dashboard"),
              _managementTile(context, "Feedback"),
              _managementTile(context, "Payment Logs"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _adminStatCard(String title, String value, Color color) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _managementTile(BuildContext context, String title) {
    return GestureDetector(
      onTap: () {
        if (title == "Manage Users") {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ManageUsersPage()));
        } else if (title == "Manage Drivers") {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ManageDriversPage()));
        } else if (title == "Rides Dashboard") {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AdminRidesDashboard()));
        } else if (title == "Feedback") {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AdminFeedbackPage()));
        } else if (title == "Payment Logs") {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentLogsPage()));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }
}