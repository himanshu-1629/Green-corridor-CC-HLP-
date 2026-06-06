import 'package:flutter/material.dart';

class ManageDriversScreen extends StatefulWidget {
  const ManageDriversScreen({super.key});

  @override
  State<ManageDriversScreen> createState() =>
      _ManageDriversScreenState();
}

class _ManageDriversScreenState
    extends State<ManageDriversScreen> {

  final List<Map<String, String>> drivers = [
    {
      "name": "Rahul Patil",
      "phone": "9876543210",
      "license": "MH-DRV-1234",
    },
    {
      "name": "Amit Sharma",
      "phone": "8765432109",
      "license": "MH-DRV-5678",
    },
    {
      "name": "Suresh Patil",
      "phone": "9988776655",
      "license": "MH-DRV-9101",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Manage Drivers"),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE53935),

        onPressed: _showAddDriverDialog,

        icon: const Icon(
          Icons.person_add,
          color: Colors.white,
        ),

        label: const Text(
          "Add Driver",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const Text(
              "Registered Drivers",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              "Manage all ambulance drivers",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              decoration: InputDecoration(
                hintText: "Search Driver...",
                prefixIcon:
                    const Icon(Icons.search),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: drivers.length,

                itemBuilder:
                    (context, index) {

                  final driver =
                      drivers[index];

                  return Container(
                    margin:
                        const EdgeInsets.only(
                            bottom: 15),

                    padding:
                        const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(
                              20),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(0.05),

                          blurRadius: 10,
                          offset:
                              const Offset(0, 5),
                        ),
                      ],
                    ),

                    child: Row(
                      children: [

                        const CircleAvatar(
                          radius: 25,
                          backgroundColor:
                              Color(0xFFFFEBEE),

                          child: Icon(
                            Icons.person,
                            color:
                                Color(0xFFE53935),
                          ),
                        ),

                        const SizedBox(
                          width: 15,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [

                              Text(
                                driver["name"]!,
                                style:
                                    const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              const SizedBox(
                                height: 5,
                              ),

                              Text(
                                "📞 ${driver["phone"]}",
                              ),

                              const SizedBox(
                                height: 5,
                              ),

                              Text(
                                "License: ${driver["license"]}",
                              ),
                            ],
                          ),
                        ),

                        const Icon(
                          Icons.arrow_forward_ios,
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

  void _showAddDriverDialog() {

    showDialog(
      context: context,

      builder: (_) {

        return AlertDialog(
          title:
              const Text("Register Driver"),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [

                TextField(
                  decoration:
                      const InputDecoration(
                    labelText:
                        "Driver Name",
                  ),
                ),

                TextField(
                  decoration:
                      const InputDecoration(
                    labelText:
                        "Phone Number",
                  ),
                ),

                TextField(
                  decoration:
                      const InputDecoration(
                    labelText:
                        "License Number",
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

              child:
                  const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {

                Navigator.pop(context);

                ScaffoldMessenger.of(
                        context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Driver Registered (Demo)",
                    ),
                  ),
                );
              },

              child:
                  const Text("Register"),
            ),
          ],
        );
      },
    );
  }
}