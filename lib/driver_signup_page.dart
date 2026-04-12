import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DriverSignupPage extends StatefulWidget {
  const DriverSignupPage({super.key});

  @override
  _DriverSignupPageState createState() => _DriverSignupPageState();
}

class _DriverSignupPageState extends State<DriverSignupPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  final licenseController = TextEditingController();
  final aadhaarController = TextEditingController();

  final vehicleModelController = TextEditingController();
  final vehicleColorController = TextEditingController();
  final vehicleNumberController = TextEditingController();

  String selectedGender = "male"; // ✅ NEW

  File? _image;
  final ImagePicker _picker = ImagePicker();

  // 📸 PICK IMAGE
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // ☁️ UPLOAD IMAGE
  Future<String?> uploadImage(String uid) async {
    if (_image == null) return null;

    final ref = FirebaseStorage.instance
        .ref()
        .child('driver_photos')
        .child('$uid.jpg');

    await ref.putFile(_image!);

    return await ref.getDownloadURL();
  }

  // 🚀 SIGNUP DRIVER
  Future<void> signUpDriver() async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      String? imageUrl = await uploadImage(uid);

      await FirebaseFirestore.instance.collection('drivers').doc(uid).set({
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "role": "driver",

        "active": true, // ✅ USED FOR MATCHING
        "gender": selectedGender, // ✅ IMPORTANT FOR FILTER

        if (imageUrl != null) "imageUrl": imageUrl,

        "documents": {
          "aadhaarLast4": aadhaarController.text.trim(),
          "licenseNumber": licenseController.text.trim(),
          "licenseVerified": true,
        },

        "payment": {
          "bankAccountLast4": "",
          "method": "",
          "paymentVerified": false,
          "upiId": "",
        },

        "rating": {
          "rating": 4.6,
          "totalTrips": 0,
        },

        "vehicle": {
          "model": vehicleModelController.text.trim(),
          "color": vehicleColorController.text.trim(),
          "number": vehicleNumberController.text.trim(),
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Driver account created successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Sign Up")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,
          child: Column(
            children: [

              // BASIC INFO
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone"),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
              ),

              const SizedBox(height: 20),

              // DOCUMENTS
              TextField(
                controller: licenseController,
                decoration: const InputDecoration(labelText: "License Number"),
              ),
              TextField(
                controller: aadhaarController,
                decoration:
                    const InputDecoration(labelText: "Aadhaar Last 4 Digits"),
              ),

              const SizedBox(height: 20),

              // VEHICLE
              TextField(
                controller: vehicleModelController,
                decoration: const InputDecoration(labelText: "Vehicle Model"),
              ),
              TextField(
                controller: vehicleColorController,
                decoration: const InputDecoration(labelText: "Vehicle Color"),
              ),
              TextField(
                controller: vehicleNumberController,
                decoration: const InputDecoration(labelText: "Vehicle Number"),
              ),

              const SizedBox(height: 20),

              // 🚺 GENDER SELECT
              DropdownButtonFormField<String>(
                value: selectedGender,
                items: const [
                  DropdownMenuItem(value: "male", child: Text("Male")),
                  DropdownMenuItem(value: "female", child: Text("Female")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedGender = value!;
                  });
                },
                decoration: const InputDecoration(labelText: "Gender"),
              ),

              const SizedBox(height: 20),

              // 📸 IMAGE
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[300],
                  backgroundImage:
                      _image != null ? FileImage(_image!) : null,
                  child: _image == null
                      ? const Icon(Icons.camera_alt, size: 30)
                      : null,
                ),
              ),

              const SizedBox(height: 10),
              const Text("Tap to upload driver photo"),

              const SizedBox(height: 30),

              // 🚀 BUTTON
              ElevatedButton(
                onPressed: signUpDriver,
                child: const Text("Create Driver Account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}