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
    // Quick micro-pause to allow browser session to settle without unnecessary lag
    await Future.delayed(const Duration(milliseconds: 250));

    try {
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
            final result = await Supabase.instance.client.auth
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

      final userData = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .single()
          .timeout(const Duration(seconds: 4));

      final role = userData['role'];

      if (!mounted) return;

      if (role == "Hospital Admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HospitalDashboard()),
        );
      } else if (role == "Driver") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DriverDashboard()),
        );
      } else if (role == "Citizen") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CitizenScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuperAdminDashboard()),
        );
      }
    } catch (e) {
      debugPrint("Auth verification fallback notice: $e");
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4E9),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF502D55).withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF935073), width: 1.5),
              ),
              child: const Icon(
                Icons.emergency_share_rounded,
                color: Color(0xFF0F357C),
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F357C)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "GREEN CORRIDOR",
              style: TextStyle(
                fontFamily: 'OpenSauceSans',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F357C),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Synchronizing Emergency Transit Grid...",
              style: TextStyle(
                fontFamily: 'PeaceSans',
                fontSize: 12,
                color: Color(0xFF334A6F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}