import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
class CitizenScreen extends StatelessWidget {
  const CitizenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text("Citizen Dashboard"),
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
      body: const Center(
        child: Text(
          "Citizen Alerts Coming Soon",
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}