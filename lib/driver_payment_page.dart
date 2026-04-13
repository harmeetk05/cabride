import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:js' as js; // ✅ Required for Razorpay Payout UI

class DriverPaymentsPage extends StatelessWidget {
  const DriverPaymentsPage({super.key});

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
            _buildWithdrawTab(driverId),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: RIDE HISTORY ---
  Widget _buildHistoryTab(String driverId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rides')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'completed') // Only show finished rides
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var rides = snapshot.data!.docs;

        if (rides.isEmpty) return const Center(child: Text("No earnings history yet"));

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            var ride = rides[index];
            double totalFare = double.tryParse(ride['fare'].toString()) ?? 0.0;
            double driverShare = totalFare * 0.70; // Calculating 70%

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              ),
              child: ListTile(
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
          },
        );
      },
    );
  }

  // --- TAB 2: WITHDRAW TAB ---
  Widget _buildWithdrawTab(String driverId) {
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
            children: [const Text("Available for Withdrawal", style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 10),
              Text("₹${balance.toStringAsFixed(2)}", 
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF2D3250))),
              const SizedBox(height: 40),
              
              // THE WITHDRAW BUTTON
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D3250),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: balance > 0 ? () => _simulateRazorpayPayout(driverId, balance) : null,
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
  void _simulateRazorpayPayout(String driverId, double amount) {
    var options = js.JsObject.jsify({
      'key': 'rzp_test_Sd2K9sVbezqLUc',
      'amount': (amount * 100).toInt(),
      'name': 'CabRide Payouts',
      'description': 'Driver Earnings Withdrawal',
      'handler': js.allowInterop((response) async {
        // Reset balance in DB
        await FirebaseFirestore.instance.collection('drivers').doc(driverId).update({
          "walletBalance": 0,
        });
        print("Payout Successful!");
      }),
    });
    var rzp = js.JsObject(js.context['Razorpay'], [options]);
    rzp.callMethod('open');
  }
}