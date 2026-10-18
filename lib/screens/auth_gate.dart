import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'hospital_dashboard.dart';
import 'driver_dashboard.dart';
import 'super_admin_dashboard.dart';
import 'citizen_screen.dart';
import 'set_new_password_screen.dart';
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
      await Future.delayed(const Duration(seconds: 2));
  final session = Supabase.instance.client.auth.currentSession;
final user = session?.user;
final url = Uri.base.toString();
debugPrint("FULL URL => $url");
if (url.contains("code=")) {
  try {
    final uri = Uri.base;
    final code = uri.queryParameters['code'];

    debugPrint("CODE => $code");

    if (code != null) {
      final result =
          await Supabase.instance.client.auth
              .exchangeCodeForSession(code);

      debugPrint("EXCHANGE SUCCESS: ${result.session.user.id}");
    }
  } catch (e) {
    debugPrint("EXCHANGE ERROR => $e");
  }

  if (!mounted) return;

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const SetNewPasswordScreen(),
    ),
  );

  return;
}
if (user == null) {
  goToWelcome();
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