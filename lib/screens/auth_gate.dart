import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

import '../widgets/medical_loading_orb.dart';
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
    // Brief settling delay to verify session without unnecessary wait
    await Future.delayed(const Duration(milliseconds: 200));

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
    return const Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MedicalLoadingOrb(
              size: 88,
            ),
            SizedBox(height: 24),
            Text(
              "GREEN CORRIDOR",
              style: TextStyle(
                fontFamily: 'NeueMontreal',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.nearBlack,
                letterSpacing: 1.4,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Connecting Critical Transit Network...",
              style: TextStyle(
                fontFamily: 'NeueMontreal',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.nearBlackMuted,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}