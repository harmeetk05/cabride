import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageVehiclesPage extends StatefulWidget {
  const ManageVehiclesPage({super.key});

  @override
  State<ManageVehiclesPage> createState() => _ManageVehiclesPageState();
}

class _ManageVehiclesPageState extends State<ManageVehiclesPage> {
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "Manage Vehicles",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3250),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search by Model or Number...",
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.indigoAccent,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Sorting vehicles by model name alphabetically
        stream: FirebaseFirestore.instance
            .collection('vehicles')
            .orderBy('model')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No vehicles found"));
          }

          // Filter logic for search (Fixed missing || operator)
          var vehicles = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String model = (data['model'] ?? "").toString().toLowerCase();
            String number = (data['number'] ?? "").toString().toLowerCase();
            return model.contains(searchQuery) || number.contains(searchQuery);
          }).toList();

          return ListView.builder(
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              var vehicle = vehicles[index].data() as Map<String, dynamic>;
              String? driverId = vehicle['driverId'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.indigoAccent.withOpacity(0.1),
                              shape: BoxShape.circle,),
                            child: const Icon(
                              Icons.directions_car,
                              color: Colors.indigoAccent,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vehicle['model']?.toUpperCase() ??
                                      "UNKNOWN MODEL",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Registration: ${vehicle['number'] ?? 'N/A'}",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              vehicle['capacity'] ?? "4 Seater",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _vehicleStat(
                            Icons.location_city,
                            "City",
                            vehicle['city'],
                          ),
                          _vehicleStat(
                            Icons.palette,
                            "Color",
                            vehicle['color'],
                          ),
                          _vehicleStat(
                            Icons.confirmation_number_outlined,
                            "RTO",
                            vehicle['rtoCode'],
                          ),
                        ],
                      ),
                      
                      const Divider(height: 30),
                      
                      // --- NEW DRIVER ASSIGNMENT SECTION ---
                      const Text(
                        "Assigned Driver",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildDriverInfo(driverId),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper widget to display individual vehicle statsWidget 
  _vehicleStat(IconData icon, String label, String? value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          value ?? "N/A",
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // --- HELPER WIDGET TO FETCH AND DISPLAY DRIVER INFO ---
  Widget _buildDriverInfo(String? driverId) {
    if (driverId == null || driverId.isEmpty) {
      return Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange[400], size: 20),
          const SizedBox(width: 8),
          const Text(
            "No driver assigned to this vehicle",
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('drivers').doc(driverId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LinearProgressIndicator(minHeight: 2));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text(
            "Driver data not found",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
          );
        }

        var driverData = snapshot.data!.data() as Map<String, dynamic>;
        String imageUrl = driverData['imageUrl'] ?? "";
        
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.indigo[50],
                backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                child: imageUrl.isEmpty 
                    ? const Icon(Icons.person, color: Colors.indigoAccent) 
                    : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverData['name'] ?? "Unknown Driver",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF2D3250),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Phone: ${driverData['phone'] ?? 'N/A'}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user, color: Colors.green, size: 18),
              ),
            ],
          ),
        );
      },
    );
  }
}