import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const GreenCorridorApp());
}

class GreenCorridorApp extends StatelessWidget {
  const GreenCorridorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(),
    );
  }
}