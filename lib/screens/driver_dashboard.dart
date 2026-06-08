import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() =>
      _DriverDashboardState();
}

class _DriverDashboardState
    extends State<DriverDashboard> {
  Map<String, dynamic>? mission;
  bool isLoading = true;

  Future<void> loadMission() async {
    try {
      final user =
          Supabase.instance.client.auth.currentUser;

      final data = await Supabase.instance.client
          .from('missions')
          .select()
          .eq('driver_id', user!.id)
          .limit(1);

      if (data.isNotEmpty) {
        mission = data.first;
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print(e);

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadMission();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Driver Dashboard"),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,

        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),

      body: mission == null
          ? const Center(
              child: Text(
                "No mission assigned",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20),

              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                    const Text(
                      "Assigned Mission",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "Patient / Organ: ${mission!['patient_name']}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Destination: ${mission!['destination']}",
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Priority / Time Limit: ${mission!['priority']}",
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Status: ${mission!['status']}",
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 55,

                      child: ElevatedButton(
                        onPressed: () {},

                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFE53935),
                          foregroundColor:
                              Colors.white,
                        ),

                        child: const Text(
                          "START MISSION",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}