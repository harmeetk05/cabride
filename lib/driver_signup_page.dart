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
  File? _image;
  final ImagePicker _picker = ImagePicker();

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
        "active": true,
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
        SnackBar(content: Text("Driver account created successfully")),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
  Future<void> pickImage() async {
  final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    setState(() {
      _image = File(pickedFile.path);
    });
  }
}
Future<String?> uploadImage(String uid) async {
  if (_image == null) return null;

  final ref = FirebaseStorage.instance
      .ref()
      .child('driver_photos')
      .child('$uid.jpg');

  await ref.putFile(_image!);

  return await ref.getDownloadURL();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Driver Sign Up")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
              TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
              TextField(controller: phoneController, decoration: InputDecoration(labelText: "Phone")),
              TextField(controller: passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),

              SizedBox(height: 20),

              TextField(controller: licenseController, decoration: InputDecoration(labelText: "License Number")),
              TextField(controller: aadhaarController, decoration: InputDecoration(labelText: "Aadhaar Last 4 Digits")),

              SizedBox(height: 20),

              TextField(controller: vehicleModelController, decoration: InputDecoration(labelText: "Vehicle Model")),
              TextField(controller: vehicleColorController, decoration: InputDecoration(labelText: "Vehicle Color")),
              TextField(controller: vehicleNumberController, decoration: InputDecoration(labelText: "Vehicle Number")),
SizedBox(height: 20),

GestureDetector(
  onTap: pickImage,
  child: CircleAvatar(
    radius: 40,
    backgroundColor: Colors.grey[300],
    backgroundImage: _image != null ? FileImage(_image!) : null,
    child: _image == null
        ? Icon(Icons.camera_alt, size: 30)
        : null,
  ),
),

SizedBox(height: 10),
Text("Tap to upload driver photo"),
              SizedBox(height: 30),

              ElevatedButton(
                onPressed: signUpDriver,
                child: Text("Create Driver Account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}