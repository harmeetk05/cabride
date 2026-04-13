import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io'; 
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  final addressController = TextEditingController();

  final licenseController = TextEditingController();
  final aadhaarController = TextEditingController();

  final vehicleModelController = TextEditingController();
  final vehicleColorController = TextEditingController();
  final vehicleNumberController = TextEditingController();

  String selectedGender = "male";
  String selectedSeater = "4 Seater";
  bool isLoading = false;

  XFile? _image; 
  final ImagePicker _picker = ImagePicker();

  // 📸 PICK IMAGE
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = pickedFile); 
    }
  }

  // ☁️ UPLOAD IMAGE TO IMGBB
  Future<String?> uploadImageToImgBB() async {
    if (_image == null) return null;

    try {
      final bytes = await _image!.readAsBytes();
      String base64Image = base64Encode(bytes);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload?key=f03f04c086e107698a5355a3b257cb97'),
      );

      request.fields['image'] = base64Image;

      var response = await request.send();
      if (response.statusCode == 200) {
        var resData = await response.stream.bytesToString();
        var json = jsonDecode(resData);
        return json['data']['url']; 
      }
    } catch (e) {
      debugPrint("ImgBB Upload Error: $e");
    }
    return null;
  }

  // 🚀 SIGNUP DRIVER
  Future<void> signUpDriver() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      String uid = userCredential.user!.uid;
      
      String? imageUrl = await uploadImageToImgBB();

      // 1️⃣ Store Driver Info
      await FirebaseFirestore.instance.collection('drivers').doc(uid).set({
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "address": addressController.text.trim(),
        "role": "driver",
        "active": true,
        "gender": selectedGender,
        "imageUrl": imageUrl ?? "", 
        // ✅ INITIALIZED WALLET AND REVENUE VARIABLES HERE
        "walletBalance": 0.0,
        "totalRevenue": 0.0,
        "documents": {
          "aadhaarLast4": aadhaarController.text.trim(),
          "licenseNumber": licenseController.text.trim().toUpperCase(),
          "licenseVerified": true,
        },
        "rating": {"rating": 4.6, "totalTrips": 0},
        "vehicleId": uid,
      });

      // 2️⃣ Store Vehicle Info
      await FirebaseFirestore.instance.collection('vehicles').doc(uid).set({
        "driverId": uid,
        "model": vehicleModelController.text.trim(),
        "color": vehicleColorController.text.trim(),"number": vehicleNumberController.text.trim().toUpperCase(),
        "capacity": selectedSeater,
        "city": "Lucknow",
        "rtoCode": "UP32",
        "lastUpdated": Timestamp.now(),
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Driver and Vehicle account created successfully"),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"))
      );
    }
    setState(() => isLoading = false);
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
              buildField(nameController, "Name"),
              buildField(emailController, "Email", isEmail: true),
              buildField(phoneController, "Phone", isPhone: true),
              buildField(passwordController, "Password", obscure: true),
              buildField(addressController, "Residential Address"),

              const Divider(),
              const Text(
                "Documents",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              buildField(licenseController, "License Number", isLicense: true),
              buildField(
                aadhaarController,
                "Aadhaar Last 4 Digits",
                isAadhaar: true,
              ),

              const Divider(),
              const Text(
                "Vehicle Details",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              buildField(vehicleModelController, "Vehicle Model"),
              buildField(vehicleColorController, "Vehicle Color"),
              buildField(
                vehicleNumberController,
                "Vehicle Number",
                isLucknowVehicle: true,
              ),

              DropdownButtonFormField<String>(
                value: selectedSeater,
                items:
                    [
                          "4 Seater",
                          "6 Seater",
                          "7 Seater",
                          "7 Seater with Sleeper",
                        ]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                onChanged: (value) => setState(() => selectedSeater = value!),
                decoration: const InputDecoration(
                  labelText: "Vehicle Capacity",
                ),
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: selectedGender,
                items: const [
                  DropdownMenuItem(value: "male", child: Text("Male")),
                  DropdownMenuItem(value: "female", child: Text("Female")),
                  DropdownMenuItem(
                    value: "transgender",
                    child: Text("Transgender"),
                  ),
                ],
                onChanged: (value) => setState(() => selectedGender = value!),
                decoration: const InputDecoration(labelText: "Gender"),
              ),

              const SizedBox(height: 20),

              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _image != null
                      ? (kIsWeb
                            ? NetworkImage(_image!.path): FileImage(File(_image!.path)) as ImageProvider): null,
                  child: _image == null
                      ? const Icon(Icons.camera_alt, size: 30)
                      : null,
                ),
              ),
              const Text("Upload driver photo"),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: isLoading ? null : signUpDriver,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Create Driver Account"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    bool isEmail = false,
    bool isPhone = false,
    bool isAadhaar = false,
    bool isLicense = false,
    bool isLucknowVehicle = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: (isPhone || isAadhaar)
            ? TextInputType.number
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return "Enter $label";
          if (isEmail &&
              !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return "Invalid Email";
          }
          if (isPhone && (!RegExp(r'^[789]\d{9}$').hasMatch(value))) {
            return "Invalid Phone";
          }
          if (isAadhaar && value.length != 4) return "Enter exactly 4 digits";
          if (isLicense &&
              !RegExp(r'^[A-Z]{2}\d{2}\d{11}$').hasMatch(value.toUpperCase())) {
            return "Invalid License Format";
          }
          if (isLucknowVehicle && !value.toUpperCase().startsWith("UP32")) {
            return "Only Lucknow (UP32) allowed";
          }
          return null;
        },
      ),
    );
  }
}