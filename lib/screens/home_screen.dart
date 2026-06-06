import 'package:flutter/material.dart';
import 'driver_dashboard.dart';
import 'citizen_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🚑 Green Corridor"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DriverDashboard(),
                  ),
                );
              },
              child: const Text("Driver Mode"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CitizenScreen(),
                  ),
                );
              },
              child: const Text("Citizen Mode"),
            ),
          ],
        ),
      ),
    );
  }
}