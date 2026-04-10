import 'package:flutter/material.dart';
import 'ride_vehicle_page.dart';

class UserPlanRidePage extends StatefulWidget {
  const UserPlanRidePage({super.key});

  @override
  State<UserPlanRidePage> createState() => _UserPlanRidePageState();
}

class _UserPlanRidePageState extends State<UserPlanRidePage> {
  final pickupController = TextEditingController();
  final dropController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Plan your ride"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: pickupController,
              decoration: const InputDecoration(
                hintText: "Pickup location",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: dropController,
              decoration: const InputDecoration(
                hintText: "Drop location",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                onPressed: () {

                  if (pickupController.text.isEmpty ||
                      dropController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Enter locations")),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RideVehiclePage(
                        pickup: pickupController.text.trim(),
                        drop: dropController.text.trim(),
                      ),
                    ),
                  );
                },
                child: const Text("Next"),
              ),
            )
          ],
        ),
      ),
    );
  }
}