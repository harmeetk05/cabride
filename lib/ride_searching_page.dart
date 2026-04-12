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
    await Future.delayed(const Duration(seconds: 2));

    // GET RIDE DATA (IMPORTANT FOR FEMALE FILTER)
    var rideDoc = await FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .get();

    bool femaleOnly = rideDoc['femaleOnly'] ?? false;

    Query query = FirebaseFirestore.instance
        .collection('drivers')
        .where('active', isEqualTo: true);

    if (femaleOnly) {
      query = query.where('gender', isEqualTo: 'female');
    }

    var drivers = await query.limit(1).get();

    if (drivers.docs.isEmpty) {
      setState(() {
        message = femaleOnly
            ? "No female driver available. Please wait..."
            : "No driver available. Please wait...";
      });

      return;
    }

    var driver = drivers.docs.first;

    // UPDATE RIDE WITH DRIVER
    await FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .update({
      "driverId": driver.id,
      "status": "assigned",
    });

    // MAKE DRIVER UNAVAILABLE
    await driver.reference.update({"active": false});

    // GO TO TRACKING PAGE
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

      body: Center(
        child: Column(
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
      ),
    );
  }
}