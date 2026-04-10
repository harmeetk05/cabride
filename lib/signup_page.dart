import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupPage extends StatefulWidget {
  @override
  final String role; // user or driver later

  const SignupPage({super.key, this.role = "user"});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final emergencyNameController = TextEditingController();
  final emergencyPhoneController = TextEditingController();
  final relationController = TextEditingController();
  final medicalNotesController = TextEditingController();

  bool isLoading = false;

  Future<void> signUpUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // 1️⃣ Create Auth account
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      // 2️⃣ Store user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "emergencyContact": emergencyNameController.text.trim(),
        "contactPhone": emergencyPhoneController.text.trim(),
        "relation": relationController.text.trim(),
        "medicalNotes": medicalNotesController.text.trim(),
        "role": widget.role,
        "createdAt": Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully!")),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              buildField(nameController, "Full Name"),
              buildField(emailController, "Email"),
              buildField(phoneController, "Phone"),
              buildField(passwordController, "Password", obscure: true),
              const SizedBox(height: 20),
              const Text("Emergency Contact",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              buildField(emergencyNameController, "Contact Name"),
              buildField(emergencyPhoneController, "Contact Phone"),
              buildField(relationController, "Relation"),
              buildField(medicalNotesController, "Medical Notes"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : signUpUser,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Sign Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildField(TextEditingController controller, String label,
      {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: (value) =>
            value == null || value.isEmpty ? "Enter $label" : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}