import 'package:flutter/material.dart';

class ManageAmbulancesScreen extends StatefulWidget {
  const ManageAmbulancesScreen({super.key});

  @override
  State<ManageAmbulancesScreen> createState() =>
      _ManageAmbulancesScreenState();
}

class _ManageAmbulancesScreenState
    extends State<ManageAmbulancesScreen> {

  final List<Map<String, String>> ambulances = [
    {
      "id": "AMB1001",
      "driver": "Rahul Patil",
      "vehicle": "MH12AB1234",
      "status": "Available",
    },
    {
      "id": "AMB1002",
      "driver": "Amit Sharma",
      "vehicle": "MH14XY9876",
      "status": "On Mission",
    },
    {
      "id": "AMB1003",
      "driver": "Suresh Patil",
      "vehicle": "MH11CD4567",
      "status": "Maintenance",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Manage Ambulances"),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE53935),
        onPressed: _showRegisterDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Register",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(
              "Hospital Ambulance Fleet",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              "Manage and monitor registered ambulances",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              decoration: InputDecoration(
                hintText: "Search Ambulance...",
                prefixIcon: const Icon(Icons.search),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: ambulances.length,

                itemBuilder: (context, index) {

                  final ambulance = ambulances[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),

                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(20),

                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        Row(
                          children: [

                            const CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  Color(0xFFFFEBEE),

                              child: Icon(
                                Icons.local_hospital,
                                color: Color(0xFFE53935),
                              ),
                            ),

                            const SizedBox(width: 15),

                            Expanded(
                              child: Text(
                                ambulance["id"]!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),

                            _statusChip(
                              ambulance["status"]!,
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        Text(
                          "Driver: ${ambulance["driver"]}",
                        ),

                        const SizedBox(height: 5),

                        Text(
                          "Vehicle: ${ambulance["vehicle"]}",
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {

    Color color;

    switch (status) {
      case "Available":
        color = Colors.green;
        break;

      case "On Mission":
        color = Colors.red;
        break;

      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showRegisterDialog() {

    showDialog(
      context: context,

      builder: (_) {

        return AlertDialog(
          title: const Text(
            "Register Ambulance",
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [

                TextField(
                  decoration: const InputDecoration(
                    labelText: "Vehicle Number",
                  ),
                ),

                TextField(
                  decoration: const InputDecoration(
                    labelText: "Driver Name",
                  ),
                ),

                TextField(
                  decoration: const InputDecoration(
                    labelText:
                        "Driver Phone Number",
                  ),
                ),

                TextField(
                  decoration: const InputDecoration(
                    labelText:
                        "Driver License Number",
                  ),
                ),
              ],
            ),
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {

                Navigator.pop(context);

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Ambulance Registered (Demo)",
                    ),
                  ),
                );
              },

              child: const Text("Register"),
            ),
          ],
        );
      },
    );
  }
}