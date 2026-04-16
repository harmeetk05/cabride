import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // ✅ Required for date grouping
import 'dart:js' as js; 

class DriverPaymentsPage extends StatelessWidget {
  const DriverPaymentsPage({super.key});

  // 🛡️ Safe Date Extractor
  DateTime _getSafeDate(Map<String, dynamic> data) {
    var rawDate = data['createdAt'] ?? data['timestamp']; 
    if (rawDate is Timestamp) {
      return rawDate.toDate();
    } else if (rawDate is String) {
      return DateTime.tryParse(rawDate) ?? DateTime.now();
    }
    return DateTime.now(); // Fallback if missing
  }

  @override
  Widget build(BuildContext context) {
    String driverId = FirebaseAuth.instance.currentUser!.uid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FD),
        appBar: AppBar(
          title: const Text("Partner Earnings", style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: const Color(0xFF2D3250),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "History", icon: Icon(Icons.history)),
              Tab(text: "Withdraw", icon: Icon(Icons.account_balance_wallet)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildHistoryTab(driverId),
            _buildWithdrawTab(context, driverId), // ✅ Passed context for SnackBar
          ],
        ),
      ),
    );
  }

  // --- TAB 1: RIDE HISTORY (NOW GROUPED BY DATE) ---
  Widget _buildHistoryTab(String driverId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rides')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'completed') 
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var rides = snapshot.data!.docs.toList();

        if (rides.isEmpty) return const Center(child: Text("No earnings history yet", style: TextStyle(color: Colors.grey)));

        // 1. Sort rides by date (Newest first)
        rides.sort((a, b) {
          DateTime dateA = _getSafeDate(a.data() as Map<String, dynamic>);
          DateTime dateB = _getSafeDate(b.data() as Map<String, dynamic>);
          return dateB.compareTo(dateA); 
        });

        // 2. Group rides by Date String
        Map<String, List<DocumentSnapshot>> groupedRides = {};
        for (var ride in rides) {
          var data = ride.data() as Map<String, dynamic>;
          DateTime date = _getSafeDate(data);
          String dateStr = DateFormat('dd MMM yyyy').format(date); 

          if (!groupedRides.containsKey(dateStr)) {
            groupedRides[dateStr] = [];
          }
          groupedRides[dateStr]!.add(ride);
        }

        List<String> sortedDates = groupedRides.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            String dateStr = sortedDates[index];
            List<DocumentSnapshot> dayRides = groupedRides[dateStr]!;
            return _buildDailySection(dateStr, dayRides);
          },
        );
      },
    );
  }

  // --- DAILY SECTION WIDGET ---
  Widget _buildDailySection(String dateStr, List<DocumentSnapshot> dayRides) {
    double dailyEarnings = 0;
    
    // Calculate daily total earnings (70% share)
    for (var ride in dayRides) {
      var data = ride.data() as Map<String, dynamic>;
      double fare = double.tryParse(data['fare'].toString()) ?? 0.0;
      dailyEarnings += (fare * 0.70);
    }return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Daily Summary Header Card
        Container(
          margin: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.green[50], // Light green for earnings
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month, size: 18, color: Colors.green),
              const SizedBox(width: 8),
              Text(dateStr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green[800])),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("${dayRides.length} Rides", style: const TextStyle(fontSize: 10, color: Colors.black54)),
                  Text("+₹${dailyEarnings.toStringAsFixed(2)}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800])),
                ],
              ),
            ],
          ),
        ),
        
        // List of transactions for this specific day
        ...dayRides.map((ride) => _buildRideCard(ride)),
      ],
    );
  }

  // --- INDIVIDUAL RIDE CARD ---
  Widget _buildRideCard(DocumentSnapshot rideDoc) {
    var data = rideDoc.data() as Map<String, dynamic>;
    double totalFare = double.tryParse(data['fare'].toString()) ?? 0.0;
    double driverShare = totalFare * 0.70; 

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE8F5E9),
          child: Icon(Icons.directions_car, color: Colors.green),
        ),
        title: Text("Earnings: ₹${driverShare.toStringAsFixed(2)}", 
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Total Fare: ₹$totalFare (70% Share)"),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  // --- TAB 2: WITHDRAW TAB ---
  Widget _buildWithdrawTab(BuildContext context, String driverId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('drivers').doc(driverId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var data = snapshot.data!.data() as Map<String, dynamic>?;
        double balance = double.tryParse(data?['walletBalance']?.toString() ?? "0") ?? 0.0;

        return Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Available for Withdrawal", style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 10),
              Text("₹${balance.toStringAsFixed(2)}", 
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF2D3250))),
              const SizedBox(height: 40),
              
              // THE WITHDRAW BUTTON
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D3250),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: balance > 0 ? () => _simulateRazorpayPayout(context, driverId, balance) : null,
                  child: const Text("Withdraw to Bank via Razorpay", 
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Payouts are processed instantly to your linked bank account.",
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  // --- SIMULATED PAYOUT ---
  void _simulateRazorpayPayout(BuildContext context, String driverId, double amount) {
    var options = js.JsObject.jsify({
      'key': 'rzp_test_Sd2K9sVbezqLUc',
      'amount': (amount * 100).toInt(),
      'name': 'CabRide Payouts',
      'description': 'Driver Earnings Withdrawal',
      'handler': js.allowInterop((response) async {
        try {
          // ✅ Safely reset balance in DB
          await FirebaseFirestore.instance.collection('drivers').doc(driverId).update({
            "walletBalance": 0,
          });
          
          // ✅ Show a success message to the driver
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Payout Successful! Money sent to your bank."),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          print("Error updating database after payout: $e");
        }
      }),
    });
    
    try {
      // ✅ Added try-catch to prevent web crashes
      var rzp = js.JsObject(js.context['Razorpay'], [options]);
      rzp.callMethod('open');
    } catch (e) {
      print("Razorpay JS Error: $e");
    }
  }
}