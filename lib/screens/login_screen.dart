import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/push_notification_service.dart';
import '../theme/app_theme.dart';
import 'citizen_screen.dart';
import 'driver_dashboard.dart';
import 'forgot_password_screen.dart';
import 'hospital_dashboard.dart';
import 'register_screen.dart';
import 'super_admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                "Please enter both email and password.",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final userId = response.user?.id;
      if (userId == null) {
        throw Exception("Login failed");
      }

      final userData = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      final role = userData['role'];

      // Save device FCM token to Supabase for emergency notifications (essential for Drivers)
      try {
        await PushNotificationService.refreshAndSaveToken();
      } catch (e) {
        debugPrint("Notice: could not refresh FCM token on login: $e");
      }

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
      } else if (role == "Super Admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuperAdminDashboard()),
        );
      } else {
        throw Exception("Unknown role");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.toString().contains("Invalid")
                      ? "Invalid email or password"
                      : "Login failed. Please verify credentials.",
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 980;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 48 : 20,
            vertical: 36,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 1040 : 480,
            ),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left Informative Branding Panel
                      Expanded(
                        flex: 11,
                        child: _buildBrandingSide(context),
                      ),
                      const SizedBox(width: 64),
                      // Right Form Card
                      Expanded(
                        flex: 10,
                        child: _buildFormCard(context),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildMobileBrandingHeader(),
                      const SizedBox(height: 24),
                      _buildFormCard(context),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingSide(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand Mark
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.emeraldLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.emerald.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.emergency_share_rounded,
                color: AppColors.emeraldDark,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GREEN CORRIDOR',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.slate900,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'OPERATIONS CONTROL PORTAL',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate500,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 36),

        // Headline
        Text(
          'Unified Access for Emergency Fleets & Trauma Centers',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: AppColors.slate900,
            height: 1.18,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 18),

        // Subtitle
        Text(
          'Sign in to dispatch green transit corridors, coordinate ambulance fleets with smart traffic grids, and reserve emergency trauma bays ahead of time.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            color: AppColors.slate600,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),

        // Feature Highlights
        _buildFeatureItem(
          icon: Icons.alt_route_rounded,
          color: AppColors.emerald,
          title: 'Sub-Second Traffic Signal Preemption',
          description: 'Automated 15km path locking with municipal traffic signal controllers.',
        ),
        const SizedBox(height: 18),
        _buildFeatureItem(
          icon: Icons.local_hospital_rounded,
          color: AppColors.primary,
          title: 'Direct Trauma Bay Synchronization',
          description: 'Real-time telemetry and ETA streams straight into hospital ER intakes.',
        ),
        const SizedBox(height: 18),
        _buildFeatureItem(
          icon: Icons.cell_tower_rounded,
          color: AppColors.info,
          title: 'Citizen Siren Radar Geofence',
          description: 'Immediate in-path alerts notifying drivers to yield lanes safely.',
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.slate600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileBrandingHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.emeraldLight,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.emerald.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: const Icon(
            Icons.emergency_share_rounded,
            color: AppColors.emeraldDark,
            size: 32,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Green Corridor',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.slate900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Emergency Transit Operations Portal',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.slate500,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.05),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sign In',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your credentials to access your operations dashboard. Ambulance drivers will automatically link their device FCM token for live sirens.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.slate500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Email Input
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
            decoration: AppDecorations.input(
              labelText: "Work Email Address",
              hintText: "admin@hospital.com",
              prefixIcon: const Icon(
                Icons.alternate_email_rounded,
                color: AppColors.slate400,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Password Input
          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => loginUser(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
            decoration: AppDecorations.input(
              labelText: "Password",
              hintText: "••••••••",
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.slate400,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.slate400,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Forgot Password Link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                foregroundColor: AppColors.primary,
              ),
              child: Text(
                "Forgot password?",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Sign In Action Button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : loginUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                shadowColor: AppColors.primary.withValues(alpha: 0.35),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Access Console",
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Divider
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.slate200)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  "Public Commuter Access",
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.slate400,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.slate200)),
            ],
          ),
          const SizedBox(height: 18),

          // Direct Citizen Radar Button (No Login Needed)
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CitizenScreen()),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.slate800,
              side: const BorderSide(color: AppColors.slate300, width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.radar_rounded, color: AppColors.emerald, size: 18),
                const SizedBox(width: 8),
                Text(
                  "Open Live Citizen Radar",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Register Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "New facility or ambulance driver? ",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.slate600,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: Text(
                  "Create Account",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}