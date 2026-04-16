import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageDriversPage extends StatefulWidget {
  const ManageDriversPage({super.key});

  @override
  State<ManageDriversPage> createState() => _ManageDriversPageState();
}

class _ManageDriversPageState extends State<ManageDriversPage> {
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // 🗑️ DELETE DRIVER
  Future<void> deleteDriver(String uid) async {
    bool confirm = await _showConfirmDialog(
      "Delete",
      "Are you sure you want to delete this driver? This cannot be undone.",
    );
    if (confirm) {
      await FirebaseFirestore.instance.collection('drivers').doc(uid).delete();
      await FirebaseFirestore.instance.collection('vehicles').doc(uid).delete();
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Driver deleted")));
    }
  }

  // 🚫 SUSPEND / ACTIVATE DRIVER
  Future<void> toggleStatus(String uid, bool currentStatus) async {
    String action = currentStatus ? "Suspend" : "Activate";
    bool confirm = await _showConfirmDialog(
      action,
      "Do you want to $action this driver?",
    );
    if (confirm) {
      await FirebaseFirestore.instance.collection('drivers').doc(uid).update({
        'active': !currentStatus,
      });
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(title, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Manage Drivers",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search drivers by name...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder(
        // ✅ ALPHABETICAL ORDERING
        stream: FirebaseFirestore.instance
            .collection('drivers')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          // Filter for Search
          var drivers = snapshot.data!.docs.where((doc) {
            String name = (doc['name'] ?? "").toString().toLowerCase();
            return name.contains(searchQuery);
          }).toList();

          if (drivers.isEmpty)
            return const Center(child: Text("No drivers found"));

          return ListView.builder(
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              var driver = drivers[index];
              var driverId = driver.id;
              bool isActive = driver['active'] ?? true;
              String? imageUrl = driver.data().containsKey('imageUrl')
                  ? driver['imageUrl']
                  : null;
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 3,
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.all(10),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.indigo[50],
                    backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                        ? NetworkImage(imageUrl)
                        : null,
                    child: (imageUrl == null || imageUrl.isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    driver['name'] ?? "Driver",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isActive ? "● Online" : "○ Suspended",
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.keyboard_arrow_down),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          infoRow(Icons.phone, driver['phone'] ?? "N/A"),
                          infoRow(Icons.email, driver['email'] ?? "N/A"),
                                                    infoRow(Icons.home , driver['address'] ?? "N/A"),

                          const SizedBox(height: 10),

                          // Documents Box
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                docRow(
                                  "License",
                                  driver['documents']['licenseNumber'],
                                ),
                                docRow(
                                  "Aadhaar",
                                  "** ** ${driver['documents']['aadhaarLast4']}",
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 15),

                          // Vehicle Info
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('vehicles')
                                .doc(driverId)
                                .get(),
                            builder: (context, vSnap) {
                              if (!vSnap.hasData || !vSnap.data!.exists)
                                return const Text("No Vehicle Info");
                              var v = vSnap.data!;
                              return Text(
                                "🚗 ${v['model']} | ${v['number']} | ${v['capacity']}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.blueGrey,
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          // ⚡ ADMIN ACTIONS
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _actionBtn(
                                label: isActive ? "Suspend" : "Activate",
                                icon: isActive
                                    ? Icons.block
                                    : Icons.check_circle,
                                color: isActive ? Colors.orange : Colors.green,
                                onTap: () => toggleStatus(driverId, isActive),
                              ),
                              _actionBtn(
                                label: "Delete",
                                icon: Icons.delete_forever,
                                color: Colors.red,
                                onTap: () => deleteDriver(driverId),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(text),
      ],
    ),
  );

  Widget docRow(String label, String val) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 12)),
      Text(
        val,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    ],
  );

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
