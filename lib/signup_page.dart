import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupPage extends StatefulWidget {
  final String role; // user or driver
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
  final disabilityController = TextEditingController(); // Optional field

  String? selectedGender;
  bool isLoading = false;

  // Validation Logic
  String? validateEmail(String? value) {
    String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regex = RegExp(pattern);
    if (value == null || value.isEmpty) return "Enter Email";
    if (!regex.hasMatch(value)) return "Enter a valid email address";
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return "Enter Phone Number";
    if (value.length != 10) return "Phone number must be 10 digits";
    if (!RegExp(r'^[789]').hasMatch(value)) return "Must start with 7, 8, or 9";
    return null;
  }

  Future signUpUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedGender == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a gender")));
      return;
    }

    setState(() => isLoading = true);
    try {
      // 1️⃣ Create Auth account
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
      String uid = userCredential.user!.uid;

      // 2️⃣ Store user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "gender": selectedGender,
        "disability": disabilityController.text.trim(), // Optional
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
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
              // Email with specific validation
              buildCustomField(emailController, "Email", validateEmail),
              // Phone with 10-digit and prefix validation
              buildCustomField(
                phoneController,
                "Phone",
                validatePhone,
                keyboardType: TextInputType.phone,
              ),
              // Gender Dropdown
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Gender",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: ["Male", "Female", "Transgender"]
                      .map(
                        (label) =>
                            DropdownMenuItem(value: label, child: Text(label)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => selectedGender = value),
                  validator: (value) => value == null ? "Select Gender" : null,
                ),
              ),

              buildField(passwordController, "Password", obscure: true),

              // Optional Disability Field
              buildField(
                disabilityController,
                "Disability (Optional)",
                isRequired: false,
              ),

              const SizedBox(height: 20),
              const Text(
                "Emergency Contact",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              buildField(emergencyNameController, "Contact Name"),
              // Emergency Phone with same validation constraints
              buildCustomField(
                emergencyPhoneController,
                "Contact Phone",
                validatePhone,
                keyboardType: TextInputType.phone,
              ),
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

  // Standard field helper
  Widget buildField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: isRequired
            ? (value) => value == null || value.isEmpty ? "Enter $label" : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  // Helper for fields with custom logic (Email/Phone)
  Widget buildCustomField(
    TextEditingController controller,
    String label,
    String? Function(String?) validator, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
