import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // 🗑️ DELETE USER
  Future<void> deleteUser(String uid) async {
    bool confirm = await _showConfirmDialog("Delete User", "Are you sure? This will permanently remove this user from the system.");
    if (confirm) {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User deleted successfully")));
    }
  }

  // 🚫 SUSPEND / ACTIVATE USER
  Future<void> toggleUserStatus(String uid, bool currentStatus) async {
    String action = currentStatus ? "Suspend" : "Activate";
    bool confirm = await _showConfirmDialog(action, "Do you want to $action this user?");
    if (confirm) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'active': !currentStatus});
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(title, style: TextStyle(color: title.contains("Suspend") || title.contains("Delete") ? Colors.red : Colors.green)),
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
        title: const Text("Manage Users", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search users by name...",
                prefixIcon: const Icon(Icons.search, color: Colors.indigoAccent),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ✅ ALPHABETICAL ORDERING
        stream: FirebaseFirestore.instance.collection('users').orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          // Filter for 'user' role and Search query
          var users = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String name = (data['name'] ?? "").toString().toLowerCase();
            bool isNormalUser = data.containsKey('role') && data['role'] == 'user';
            return isNormalUser && name.contains(searchQuery);
          }).toList();if (users.isEmpty) {
            return const Center(child: Text("No matching users available"));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              var userData = user.data() as Map<String, dynamic>;
              String userId = user.id;
              bool isActive = userData['active'] ?? true;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigoAccent.withOpacity(0.1),
                    child: const Icon(Icons.person, color: Colors.indigoAccent),
                  ),
                  title: Text(
                    userData['name'] ?? "No Name",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    isActive ? "Active Account" : "Suspended",
                    style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 12),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          _detailRow(Icons.email_outlined, "Email", userData['email']),
                          _detailRow(Icons.phone_android, "Phone", userData['phone']),
                          
                          const SizedBox(height: 15),
                          const Text("🚨 Emergency Contact Info", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                          const SizedBox(height: 8),
                          
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              children: [
                                _docRow("Contact Name", userData['emergencyContact']),
                                _docRow("Contact Phone", userData['contactPhone']),
                                _docRow("Relation", userData['relation']),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 15),
                          const Text("🩺 Medical Information", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                          const SizedBox(height: 5),
                          Text(userData['medicalNotes'] ?? "No medical notes provided", style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                          
                          const SizedBox(height: 15),
                          Text(
                            "Joined: ${userData['createdAt'] != null ? (userData['createdAt'] as Timestamp).toDate().toString().substring(0, 10) : 'N/A'}",
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),

                          const SizedBox(height: 20),

                          // ⚡ ACTIONS
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(onPressed: () => toggleUserStatus(userId, isActive),
                                  icon: Icon(isActive ? Icons.block : Icons.check_circle, size: 18),
                                  label: Text(isActive ? "Suspend" : "Activate"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isActive ? Colors.orange : Colors.green,
                                    side: BorderSide(color: isActive ? Colors.orange : Colors.green),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => deleteUser(userId),
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  label: const Text("Delete"),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                ),
                              ),
                            ],
                          )
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

  Widget _detailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.indigoAccent),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value ?? "N/A", style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _docRow(String label, String? val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Text(val ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red)),
        ],
      ),
    );
  }
}