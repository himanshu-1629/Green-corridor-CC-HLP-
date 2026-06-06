import 'package:flutter/material.dart';

class CitizenScreen extends StatelessWidget {
  const CitizenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Citizen Mode"),
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