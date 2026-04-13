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
import 'manage_vehicles_page.dart';
import 'user_payments_history_page.dart';

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
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscureText = true;

  // Logic for Login
  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      // 1. Sign in with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      String uid = userCredential.user!.uid;

      // 2. Check if they are a Driver
      DocumentSnapshot driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(uid)
          .get();

      if (driverDoc.exists) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DriverHome()),
          );
        }
        return; // Stop here if driver found
      }

      // 3. Check if they are a User (or Admin)
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        String role = userDoc['role'] ?? 'user';

        if (mounted) {
          if (role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminHome()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const UserHome()),
            );
          }
        }
      } else {
        // If UID exists in Auth but not in any collection (rare case)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account data not found.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => isLoading = false);
  }

  // Logic for the "Sign Up" choice popup
  void _showSignUpOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        height: 220,
        child: Column(
          children: [
            const Text(
              "Create an account as",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3250),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.indigoAccent,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: const Text("User / Rider"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupPage()),
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF2D3250),
                child: Icon(Icons.drive_eta, color: Colors.white),
              ),
              title: const Text("Driver / Captain"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DriverSignupPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Regal Logo Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      size: 50,
                      color: Colors.indigoAccent,
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    "CabRide Login",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3250),
                    ),
                  ),
                  const Text(
                    "Enter details to access your account",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 40),

                  // Email
                  buildInputField(
                    controller: emailController,
                    label: "Email Address",
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 20),

                  // Password
                  buildInputField(
                    controller: passwordController,
                    label: "Password",
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),

                  // Forgot Password - Connected to your ForgotPassword class
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPassword(),
                          ),
                        );
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: Colors.indigoAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D3250),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 2,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Sign Up Link - Triggers Selection Logic
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "New here? ",
                        style: TextStyle(color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: _showSignUpOptions,
                        child: const Text(
                          "Create Account",
                          style: TextStyle(
                            color: Colors.indigoAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widget for modern input styling
  Widget buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscureText : false,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.indigoAccent, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.indigoAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
      validator: (value) => value == null || value.isEmpty ? "Required" : null,
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
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

  // ✅ Logout Function
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      // ✅ REGAL DRAWER FOR USER
      drawer: Drawer(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            var userData = snapshot.data!.data() as Map<String, dynamic>;

            return Column(
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Color(0xFF2D3250)),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.indigoAccent[100],
                    child: const Icon(
                      Icons.person,
                      size: 45,
                      color: Colors.white,
                    ),
                  ),
                  accountName: Text(
                    userData['name'] ?? "User",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  accountEmail: Text(userData['email'] ?? ""),
                ),
                _drawerTile(
                  context,
                  "My Profile",
                  Icons.account_circle_outlined,
                  onTap: () => _showEditProfileDialog(context, userData),
                ),
                _drawerTile(context, "My Rides", Icons.history),
                _drawerTile(
                  context,
                  "Payments",
                  Icons.payment_outlined,
                  onTap: () {
                    Navigator.pop(context); // Close the drawer first
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserPaymentsHistoryPage(),
                      ),
                    );
                  },
                ),
                const Divider(),
                _drawerTile(context, "Help & Support", Icons.help_outline),
                _drawerTile(
                  context,
                  "Logout",
                  Icons.logout,
                  color: Colors.redAccent,
                  onTap: logout,
                ),
              ],
            );
          },
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D3250)),
        title: const Text(
          "CabRide",
          style: TextStyle(
            color: Color(0xFF2D3250),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            children: [
              const SizedBox(height: 10),
              const Text(
                "Go anywhere with",
                style: TextStyle(fontSize: 24, color: Colors.grey),
              ),
              const Text(
                "CabRide",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3250),
                ),
              ),

              const SizedBox(height: 30),

              // 🚗 RIDE BOOKING CARD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _locationField(
                      pickupController,
                      "Pickup location",
                      Icons.radio_button_checked,
                      Colors.green,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Divider(),
                    ),
                    _locationField(
                      dropController,
                      "Drop location",
                      Icons.location_on,
                      Colors.redAccent,
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D3250),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () {
                          String pickup = pickupController.text.trim();
                          String drop = dropController.text.trim();
                          if (pickup.isEmpty || drop.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Enter pickup & drop"),
                              ),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RideVehiclePage(pickup: pickup, drop: drop),
                            ),
                          );
                        },
                        child: const Text(
                          "See Prices",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              const Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3250),
                ),
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  _quickActionCard(
                    context,
                    "Emergency",
                    Colors.red,
                    Icons.emergency_share,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EmergencyPage()),
                      );
                    },
                  ),
                  const SizedBox(width: 15),
                  _quickActionCard(
                    context,
                    "Payments",
                    Colors.blue,
                    Icons.account_balance_wallet,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserPaymentPage(),
                        ),
                      );
                    },
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

  // ✅ EDIT PROFILE DIALOG
  void _showEditProfileDialog(BuildContext context, Map<String, dynamic> data) {
    final nameCtrl = TextEditingController(text: data['name']);
    final phoneCtrl = TextEditingController(text: data['phone']);
    final emergencyCtrl = TextEditingController(text: data['emergencyContact']);
    final relationCtrl = TextEditingController(text: data['relation']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 25,
          right: 25,
          top: 25,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Update Profile",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _editField(nameCtrl, "Full Name", Icons.person_outline),
              _editField(phoneCtrl, "Phone Number", Icons.phone_android),
              const Divider(height: 30),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Emergency Details",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _editField(
                emergencyCtrl,
                "Emergency Contact Name",
                Icons.contact_phone_outlined,
              ),
              _editField(
                relationCtrl,
                "Relation (e.g. Son, Daughter)",
                Icons.people_outline,
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D3250),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .update({
                        'name': nameCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'emergencyContact': emergencyCtrl.text.trim(),
                        'relation': relationCtrl.text.trim(),
                      });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Profile Updated Successfully!"),
                    ),
                  );
                },
                child: const Text(
                  "Save Profile",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPERS ---

  Widget _locationField(
    TextEditingController ctrl,
    String hint,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 15),
        Expanded(
          child: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              hintStyle: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickActionCard(
    BuildContext context,
    String title,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerTile(
    BuildContext context,
    String title,
    IconData icon, {
    VoidCallback? onTap,
    Color color = const Color(0xFF2D3250),
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      onTap: onTap ?? () => Navigator.pop(context),
    );
  }

  Widget _editField(TextEditingController ctrl, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  bool isOnline = true;
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

  // ✅ LOGOUT FUNCTION
  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      // --- REGAL DRAWER ---
      drawer: Drawer(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('drivers').doc(uid).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            var data = snapshot.data?.data() as Map<String, dynamic>?;
            String name = data?['name'] ?? "Driver";
            String email = data?['email'] ?? "";
            String? imageUrl = data?['imageUrl'];

            return Column(
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Color(0xFF2D3250)),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
                    child: (imageUrl == null || imageUrl.isEmpty) 
                        ? const Icon(Icons.person, size: 40, color: Color(0xFF2D3250)) 
                        : null,
                  ),
                  accountName: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  accountEmail: Text(email),
                ),
                _drawerTile(context, "My Profile", Icons.person_outline, 
                  onTap: () => _showProfileDialog(context, data!)),
                _drawerTile(context, "Ride History", Icons.history),
                _drawerTile(context, "Earnings", Icons.account_balance_wallet_outlined,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverPaymentsPage()))),
                const Divider(),
                _drawerTile(context, "Emergency Help", Icons.emergency_share, color: Colors.red,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencyPage()))),
                _drawerTile(context, "Logout", Icons.logout, color: Colors.redAccent, onTap: () => logout(context)),
              ],
            );
          },
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D3250)),
        centerTitle: true,
        title: const Text("Driver Dashboard", style: TextStyle(color: Color(0xFF2D3250), fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            children: [
              const SizedBox(height: 10),

              // --- ONLINE/OFFLINE TOGGLE ---
              Container(
                padding: const EdgeInsets.all(20),decoration: BoxDecoration(
                  color: isOnline ? Colors.green[50] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isOnline ? Colors.green.shade200 : Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isOnline ? "YOU ARE ONLINE" : "YOU ARE OFFLINE",
                          style: TextStyle(fontWeight: FontWeight.bold, color: isOnline ? Colors.green[700] : Colors.grey[700])),
                        Text("Set status to receive rides", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                    Switch(
                      value: isOnline,
                      onChanged: (val) => setState(() => isOnline = val),
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              const Text("Real-time Stats", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3250))),
              const SizedBox(height: 15),

              // --- 🚀 DYNAMIC STATS (NESTED STREAMS) ---
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('rides').where('driverId', isEqualTo: uid).where('status', isEqualTo: 'completed').snapshots(),
                builder: (context, rideSnapshot) {
                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('drivers').doc(uid).snapshots(),
                    builder: (context, driverSnapshot) {
                      int rideCount = rideSnapshot.hasData ? rideSnapshot.data!.docs.length : 0;
                      var driverData = driverSnapshot.data?.data() as Map<String, dynamic>?;
                      double balance = double.tryParse(driverData?['walletBalance']?.toString() ?? "0") ?? 0.0;

                      return Row(
                        children: [
                          Expanded(
                            child: _statCard("Rides", "$rideCount", Colors.blue, Icons.directions_car),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _statCard("Wallet", "₹${balance.toStringAsFixed(2)}", Colors.orange, Icons.currency_rupee, 
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverPaymentsPage()))),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 30),
              const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3250))),
              const SizedBox(height: 15),

              _actionTile(
                title: "New Ride Requests",
                subtitle: "View pending bookings",
                icon: Icons.notifications_active,
                color: Colors.indigo,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverRequestsPage())),
              ),
              const SizedBox(height: 12),

              _actionTile(
                title: "Emergency Alert",
                subtitle: "Panic button for immediate help",
                icon: Icons.warning_amber_rounded,
                color: Colors.red,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencyPage())),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPERS ---
  Widget _statCard(String title, String val, Color color, IconData icon, {VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)],
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 10),
              FittedBox(child: Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      );

  Widget _actionTile({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) => 
    ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.all(15),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
    );

  void _showProfileDialog(BuildContext context, Map<String, dynamic> data) {
    TextEditingController phoneCtrl = TextEditingController(text: data['phone']);
    TextEditingController addrCtrl = TextEditingController(text: data['address']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Update My Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _editField(phoneCtrl, "Phone Number", Icons.phone),
            _editField(addrCtrl, "Home Address", Icons.home),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D3250), minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('drivers').doc(uid).update({
                  'phone': phoneCtrl.text.trim(),
                  'address': addrCtrl.text.trim(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated!")));
              },
              child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(BuildContext context, String title, IconData icon, {VoidCallback? onTap, Color color = const Color(0xFF2D3250)}) => 
    ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      onTap: onTap ?? () => Navigator.pop(context),
    );

  Widget _editField(TextEditingController ctrl, String label, IconData icon) => 
    Padding(padding: const EdgeInsets.only(bottom: 15), child: TextField(controller: ctrl, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))));
}
class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  // ✅ Logout Function
  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
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
    final User? admin = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // Slightly "Regal" off-white
      // ✅ THE SIDE MENU (DRAWER)
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // ✅ ADMIN PROFILE HEADER
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF2D3250)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.indigoAccent[100],
                child: const Icon(
                  Icons.admin_panel_settings,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              accountName: const Text(
                "Admin Control",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(admin?.email ?? "admin@cabride.com"),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerTile(context, "Manage Users", Icons.people_outline),
                  _drawerTile(
                    context,
                    "Manage Drivers",
                    Icons.drive_eta_outlined,
                  ),
                  _drawerTile(
                    context,
                    "Manage Vehicles",
                    Icons.directions_car_filled_outlined,
                  ), // ✅ NEW TAB
                  _drawerTile(
                    context,
                    "Rides Dashboard",
                    Icons.analytics_outlined,
                  ),
                  _drawerTile(context, "Feedback", Icons.feedback_outlined),
                  _drawerTile(
                    context,
                    "Payment Logs",
                    Icons.account_balance_wallet_outlined,
                  ),
                  const Divider(),
                  _drawerTile(context, "Logout", Icons.logout, isLogout: true),
                ],
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D3250)),
        title: const Text(
          "CabRide Admin",
          style: TextStyle(
            color: Color(0xFF2D3250),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // Quick View Profile logic can go here or use the Drawer header
            },
            icon: const Icon(Icons.account_circle),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                "Welcome back, Admin!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3250),
                ),
              ),
              const Text(
                "Here's what's happening today",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 25),

              // ✅ LIVE STATS SECTION
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .snapshots(),
                builder: (context, userSnap) {
                  return StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('drivers')
                        .snapshots(),
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
                                          "Total Users",
                                          "${userSnap.data?.docs.length ?? 0}",
                                          Colors.blue,
                                          Icons.person,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: _adminStatCard(
                                          "Total Drivers",
                                          "${driverSnap.data?.docs.length ?? 0}",
                                          Colors.green,
                                          Icons.sports_motorsports,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _adminStatCard(
                                          "Active Rides",
                                          "${rideSnap.data ?? 0}",
                                          Colors.orange,
                                          Icons.map,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: _adminStatCard(
                                          "Revenue",
                                          "₹${(revenueSnap.data ?? 0).toStringAsFixed(0)}",
                                          Colors.purple,
                                          Icons.currency_rupee,
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

              const SizedBox(height: 40),

              const Text(
                "Quick Response",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3250),
                ),
              ),
              const SizedBox(height: 15),

              // ✅ EMERGENCY BUTTON (Stays on main dashboard)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmergencyPage()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5F6D), Color(0xFFFFC371)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emergency_share,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "EMERGENCY REQUESTS",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "Respond to alerts immediately",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ DRAWER TILE HELPER
  Widget _drawerTile(
    BuildContext context,
    String title,
    IconData icon, {
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.redAccent : const Color(0xFF2D3250),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.redAccent : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (isLogout) {
          logout(context);
        } else if (title == "Manage Users") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageUsersPage()),
          );
        } else if (title == "Manage Drivers") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageDriversPage()),
          );
        } else if (title == "Manage Vehicles") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageVehiclesPage()),
          );
        } else if (title == "Rides Dashboard") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminRidesDashboard()),
          );
        } else if (title == "Feedback") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminFeedbackPage()),
          );
        } else if (title == "Payment Logs") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PaymentLogsPage()),
          );
        } else if (title == "Emergency") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmergencyPage()),
          );
        }
      },
    );
  }

  // ✅ STAT CARD HELPER
  Widget _adminStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3250),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
