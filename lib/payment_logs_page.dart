import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
import 'dart:js' as js;

class PaymentLogsPage extends StatelessWidget {
  const PaymentLogsPage({super.key});

  // 🛡️ Safe Date Extractor
  DateTime _getSafeDate(Map<String, dynamic> data) {
    var rawDate = data['createdAt'] ?? data['timestamp']; 
    if (rawDate is Timestamp) {
      return rawDate.toDate();
    } else if (rawDate is String) {
      return DateTime.tryParse(rawDate) ?? DateTime.now();
    }
    return DateTime.now(); 
  }

  // 🔍 NEW: Function to fetch real names from IDs
  Future<Map<String, String>> _fetchNames(String userId, String driverId) async {
    String userName = "Unknown User";
    String driverName = "Unknown Driver";

    try {
      if (userId.isNotEmpty) {
        var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (userDoc.exists) userName = userDoc.data()?['name'] ?? "Unknown User";
      }
      if (driverId.isNotEmpty) {
        var driverDoc = await FirebaseFirestore.instance.collection('drivers').doc(driverId).get();
        if (driverDoc.exists) driverName = driverDoc.data()?['name'] ?? "Unknown Driver";
      }
    } catch (e) {
      debugPrint("Error fetching names: $e");
    }
    
    return {"user": userName, "driver": driverName};
  }

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
            .where('paymentStatus', isEqualTo: 'paid') 
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var rides = snapshot.data?.docs.toList() ?? [];

          // Sort rides by date (Newest first)
          rides.sort((a, b) {
            DateTime dateA = _getSafeDate(a.data() as Map<String, dynamic>);
            DateTime dateB = _getSafeDate(b.data() as Map<String, dynamic>);
            return dateB.compareTo(dateA); 
          });

          // Group rides by Date String and calculate global totals
          Map<String, List<DocumentSnapshot>> groupedRides = {};
          double globalGrossRevenue = 0;

          for (var ride in rides) {
            var data = ride.data() as Map<String, dynamic>;
            double fare = double.tryParse(data['fare'].toString()) ?? 0.0;
            globalGrossRevenue += fare;

            DateTime date = _getSafeDate(data);
            String dateStr = DateFormat('dd MMM yyyy').format(date); 

            if (!groupedRides.containsKey(dateStr)) {
              groupedRides[dateStr] = [];
            }
            groupedRides[dateStr]!.add(ride);
          }

          double globalAdminProfit = globalGrossRevenue * 0.30;
          List<String> sortedDates = groupedRides.keys.toList();

          return Column(
            children: [
              _buildRevenueHeader(context, globalGrossRevenue, globalAdminProfit),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Daily Breakdown", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3250))),),
              ),
              
              Expanded(
                child: rides.isEmpty 
                  ? const Center(child: Text("No payment data available", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: sortedDates.length,
                      itemBuilder: (context, index) {
                        String dateStr = sortedDates[index];
                        List<DocumentSnapshot> dayRides = groupedRides[dateStr]!;
                        return _buildDailySection(dateStr, dayRides);
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- DAILY SECTION WIDGET ---
  Widget _buildDailySection(String dateStr, List<DocumentSnapshot> dayRides) {
    double dailyGross = 0;
    
    for (var ride in dayRides) {
      var data = ride.data() as Map<String, dynamic>;
      dailyGross += double.tryParse(data['fare'].toString()) ?? 0.0;
    }
    
    double dailyDriverShare = dailyGross * 0.70;
    double dailyAdminProfit = dailyGross * 0.30;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.indigo[50], 
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.indigo.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month, size: 18, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                  const Spacer(),
                  Text("${dayRides.length} Rides", style: const TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.bold)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Colors.black12),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _dailyStatItem("Gross Received", dailyGross, Colors.black87),
                  _dailyStatItem("Paid to Drivers", dailyDriverShare, Colors.orange[800]!),
                  _dailyStatItem("Company Profit", dailyAdminProfit, Colors.green[700]!),
                ],
              ),
            ],
          ),
        ),
        
        ...dayRides.map((ride) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildTransactionCard(ride),
        )),
      ],
    );
  }

  Widget _dailyStatItem(String title, double amount, Color amountColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text("₹${amount.toStringAsFixed(0)}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: amountColor)),
      ],
    );
  }

  // --- REGAL HEADER WITH METRICS & WITHDRAW ---
  Widget _buildRevenueHeader(BuildContext context, double gross, double profit) {
    return Container(
      padding: const EdgeInsets.all(25),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2D3250), Color(0xFF4A55A2)]),borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _revenueStat("Lifetime Gross Revenue", "₹${gross.toStringAsFixed(0)}", Icons.account_balance),
              _revenueStat("Lifetime Admin Profit", "₹${profit.toStringAsFixed(0)}", Icons.trending_up),
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
  }

  Widget _revenueStat(String title, String value, IconData icon) {
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

  // --- UPDATED TRANSACTION ITEM WITH NAMES ---
  Widget _buildTransactionCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    double fare = double.tryParse(data['fare'].toString()) ?? 0.0;
    double commission = fare * 0.30;
    String userId = data['userId']?.toString() ?? "";
    String driverId = data['driverId']?.toString() ?? "";

    return FutureBuilder<Map<String, String>>(
      future: _fetchNames(userId, driverId),
      builder: (context, snapshot) {
        String userName = "Loading...";
        String driverName = "Loading...";

        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          userName = snapshot.data!['user']!;
          driverName = snapshot.data!['driver']!;
        }

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
            title: Text("Txn ID: ${doc.id.substring(0, 8).toUpperCase()}", 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                
                // ✅ NEW VISUAL PAYMENT FLOW
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(userName, 
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.green),
                      ),
                      Icon(Icons.directions_car, size: 14, color: Colors.orange[700]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(driverName, 
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                Text("Driver Share (70%): ₹${(fare * 0.7).toStringAsFixed(2)}", 
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
        debugPrint("Corporate Withdrawal Successful!");
      }),
      'theme': {'color': '#2D3250'}
    });
    
    try {
      var rzp = js.JsObject(js.context['Razorpay'], [options]);
      rzp.callMethod('open');
    } catch (e) {
      debugPrint("Razorpay JS Error: $e");
    }
  }
}