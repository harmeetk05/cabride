import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ride_tracking_page.dart';

class RideSearchingPage extends StatefulWidget {
  final String rideId;

  const RideSearchingPage({super.key, required this.rideId});

  @override
  State<RideSearchingPage> createState() => _RideSearchingPageState();
}

class _RideSearchingPageState extends State<RideSearchingPage> {

  String message = "Searching for driver...";

  @override
  void initState() {
    super.initState();
    assignDriver();
  }

  Future<void> assignDriver() async {

    await Future.delayed(const Duration(seconds: 3));

    var drivers = await FirebaseFirestore.instance
        .collection('drivers')
        .where('available', isEqualTo: true)
        .limit(1)
        .get();

    if (drivers.docs.isEmpty) {
      setState(() {
        message = "No driver yet. Please wait...";
      });
      return;
    }

    var driver = drivers.docs.first;

    await FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .update({
      "driverId": driver.id,
      "status": "assigned",
    });

    await driver.reference.update({"available": false});

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RideTrackingPage(
          rideId: widget.rideId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Finding Driver")),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(message),

          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('rides')
                  .doc(widget.rideId)
                  .update({"status": "cancelled"});

              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          )
        ],
      ),
    );
  }
}