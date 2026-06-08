import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_screen.dart';
import 'hospital_dashboard.dart';
import 'driver_dashboard.dart';
import 'super_admin_dashboard.dart';
import 'citizen_screen.dart';
import 'welcome_screen.dart';
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  
 @override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    checkUser();
  });
}

  Future<void> checkUser() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const WelcomeScreen(),
    ),
  );
  return;
}

    try {
      final userData = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      final role = userData['role'];

      if (!mounted) return;

      if (role == "Hospital Admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HospitalDashboard(),
          ),
        );
      } else if (role == "Driver") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DriverDashboard(),
          ),
        );
      } else if (role == "Citizen") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const CitizenScreen(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const SuperAdminDashboard(),
          ),
        );
      }
    }catch (e) {
  goToWelcome();
}
  }

void goToWelcome() {
  if (!mounted) return;

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const WelcomeScreen(),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}