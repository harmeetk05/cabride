import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:js' as js; // ✅ Required for simulated payout UI

class PaymentLogsPage extends StatelessWidget {
  const PaymentLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Financial Operations", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3250))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D3250)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .where('paymentStatus', isEqualTo: 'paid') // Only count successful payments
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          double grossRevenue = 0;
          var rides = snapshot.data?.docs ?? [];

          // Calculate totals
          for (var ride in rides) {
            grossRevenue += double.tryParse(ride['fare'].toString()) ?? 0.0;
          }
          double adminProfit = grossRevenue * 0.30;

          return Column(
            children: [
              _buildRevenueHeader(context, grossRevenue, adminProfit),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Recent Transactions", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3250))),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: rides.length,
                  itemBuilder: (context, index) {
                    var ride = rides[index];
                    return _buildTransactionCard(ride);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- REGAL HEADER WITH METRICS & WITHDRAW ---
  Widget _buildRevenueHeader(BuildContext context, double gross, double profit) {
    return Container(
      padding: const EdgeInsets.all(25),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2D3250), Color(0xFF4A55A2)]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _revenueStat("Gross Revenue", "₹${gross.toStringAsFixed(0)}", Icons.account_balance),
              _revenueStat("Admin Profit (30%)", "₹${profit.toStringAsFixed(0)}", Icons.trending_up),
            ],
          ),
          const SizedBox(height: 25),
          const Divider(color: Colors.white24),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2D3250),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () => _simulateAdminWithdrawal(profit),
              icon: const Icon(Icons.file_download_outlined),
              label: const Text("Withdraw Profits to Company Account", 
                style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }Widget _revenueStat(String title, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white60, size: 16),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // --- TRANSACTION ITEM ---
  Widget _buildTransactionCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    double fare = double.tryParse(data['fare'].toString()) ?? 0.0;
    double commission = fare * 0.30;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: Colors.indigo[50],
          child: const Icon(Icons.receipt_long, color: Color(0xFF2D3250)),
        ),
        title: Text("Transaction ID: ${doc.id.substring(0, 8)}", 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("User ID: ${data['userId'].toString().substring(0, 5)}..."),
            Text("Driver Share (70%): ₹${(fare * 0.7).toStringAsFixed(2)}"),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("+₹${commission.toStringAsFixed(2)}", 
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
            const Text("Commission", style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // --- RAZORPAY WITHDRAWAL SIMULATION ---
  void _simulateAdminWithdrawal(double amount) {
    var options = js.JsObject.jsify({
      'key': 'rzp_test_Sd2K9sVbezqLUc',
      'amount': (amount * 100).toInt(),
      'name': 'CabRide Corporate',
      'description': 'Internal Profit Payout',
      'handler': js.allowInterop((response) {
        print("Corporate Withdrawal Successful!");
      }),
      'theme': {'color': '#2D3250'}
    });
    var rzp = js.JsObject(js.context['Razorpay'], [options]);
    rzp.callMethod('open');
  }
}