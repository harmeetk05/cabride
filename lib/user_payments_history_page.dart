import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class UserPaymentsHistoryPage extends StatelessWidget {
  const UserPaymentsHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "Payment History",
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3250)),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D3250)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payments')
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true) 
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Error: ${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var paymentDoc = snapshot.data!.docs[index];
              return _paymentHistoryCard(paymentDoc);
            },
          );
        },
      ),
    );
  }

  Widget _paymentHistoryCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;

    // 🛡️ BULLETPROOF DATE PARSING
    DateTime date = DateTime.now(); // Fallback if missing
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        date = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        // Tries to parse old manual string entries safely
        date = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
      }
    }
    String formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);

    bool isCompleted = data['status'] == 'completed' || data['status'] == 'paid';
    String method = data['method'] ?? 'cash';
    String amount = data['amount']?.toString() ?? '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: method.toLowerCase() == 'upi' ? Colors.indigo[50] : Colors.green[50],
            child: Icon(
              method.toLowerCase() == 'upi' ? Icons.qr_code_scanner : Icons.payments_outlined,
              color: method.toLowerCase() == 'upi' ? Colors.indigo : Colors.green,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,children: [
                const Text(
                  "Ride Payment",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹$amount",
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 18, 
                  color: Color(0xFF2D3250),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (data['status'] ?? 'pending').toString().toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 20),
          const Text(
            "No payments recorded yet",
            style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}