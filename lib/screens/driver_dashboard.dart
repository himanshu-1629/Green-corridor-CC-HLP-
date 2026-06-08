import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
class DriverDashboard extends StatelessWidget {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // DRIVER PROFILE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),

              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "👤 Rahul Patil",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 10),

                  Text("Driver ID: DRV1001"),

                  SizedBox(height: 5),

                  Text("Phone: +91 9876543210"),

                  SizedBox(height: 15),

                  Text(
                    "🚑 Ambulance Details",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 5),

                  Text("Ambulance ID: AMB1001"),

                  SizedBox(height: 5),

                  Text("Vehicle Number: MH12AB1234"),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Assigned Mission",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            // MISSION CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Mission ID: MIS1001",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "Mission Type: Heart Transport",
                  ),

                  SizedBox(height: 5),

                  const Text(
                    "Source Hospital: Ruby Hall Clinic",
                  ),

                  SizedBox(height: 5),

                  const Text(
                    "Destination Hospital: Sahyadri Hospital",
                  ),

                  SizedBox(height: 5),

                  const Text(
                    "Time Limit: 45 mins",
                  ),

                  SizedBox(height: 5),

                  const Text(
                    "Priority: 🔴 High",
                  ),

                  SizedBox(height: 20),

                  const Text(
                    "Mission Status",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),

                    decoration: BoxDecoration(
                      color: Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.all(
                        Radius.circular(20),
                      ),
                    ),

                    child: Text(
                      "🟠 Pending",
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // START JOURNEY
            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed: () {},

                icon: const Icon(Icons.play_arrow),

                label: const Text(
                  "START JOURNEY",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // VIEW DETAILS
            SizedBox(
              width: double.infinity,
              height: 55,

              child: OutlinedButton.icon(
                onPressed: () {},

                icon: const Icon(Icons.assignment),

                label: const Text(
                  "VIEW MISSION DETAILS",
                ),

                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // CONTACT SOURCE
            SizedBox(
              width: double.infinity,
              height: 55,

              child: OutlinedButton.icon(
                onPressed: () {},

                icon: const Icon(Icons.phone),

                label: const Text(
                  "CONTACT SOURCE HOSPITAL",
                ),

                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // CONTACT DESTINATION
            SizedBox(
              width: double.infinity,
              height: 55,

              child: OutlinedButton.icon(
                onPressed: () {},

                icon: const Icon(Icons.local_hospital),

                label: const Text(
                  "CONTACT DESTINATION HOSPITAL",
                ),

                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}