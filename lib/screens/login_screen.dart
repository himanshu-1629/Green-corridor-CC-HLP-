import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/push_notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/tactile_button.dart';
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
          backgroundColor: AppColors.navy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.sky, width: 1.5),
          ),
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.sky, size: 20),
              SizedBox(width: 10),
              Text(
                "Please enter both email and password.",
                style: TextStyle(
                  fontFamily: AppTypography.fontBody,
                  color: AppColors.cream,
                  fontWeight: FontWeight.w600,
                ),
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
        throw Exception("Authentication credentials could not be verified.");
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HospitalDashboard()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.navyDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.sky, width: 1.5),
          ),
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.sky, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Authentication failure: ${e.toString().replaceAll('Exception: ', '')}",
                  style: const TextStyle(
                    fontFamily: AppTypography.fontBody,
                    color: AppColors.cream,
                    fontWeight: FontWeight.w600,
                  ),
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
      backgroundColor: Colors.white, // Global Pure White Canvas #FFFFFF
      body: Stack(
        children: [
          // Ambient Warm Peach & Soft Ivory halo behind left branding
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 580,
              height: 580,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.warmPeach.withValues(alpha: 0.22),
                    AppColors.softIvory.withValues(alpha: 0.35),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -80,
            child: Container(
              width: 520,
              height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.mutedBerry.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Central content
          SafeArea(
            child: Center(
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
                            const SizedBox(width: 56),
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
                            const SizedBox(height: 28),
                            _buildFormCard(context),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingSide(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand Mark with Skeuomorphic Medallion
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: AppDecorations.iconMedallion(size: 48, isDark: true),
              child: const Icon(
                Icons.emergency_share_rounded,
                color: AppColors.warmPeach,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GREEN CORRIDOR',
                  style: TextStyle(
                    fontFamily: AppTypography.fontHeading,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.deepViolet,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  'OPERATIONS CONTROL PORTAL',
                  style: TextStyle(
                    fontFamily: AppTypography.fontBody,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mutedBerry,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 36),

        // Headline
        const Text(
          'Connecting Lives. Across Every Mile.',
          style: TextStyle(
            fontFamily: AppTypography.fontHeading,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: AppColors.deepViolet,
            height: 1.18,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 16),

        // Subtitle
        Text(
          'Bringing hospitals, ambulances, and time-critical medical transportation workflows together through one coordinated platform.',
          style: TextStyle(
            fontFamily: AppTypography.fontBody,
            fontSize: 15,
            color: AppColors.deepViolet.withValues(alpha: 0.82),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),

        // 3D Sculpted Feature Cards
        _buildFeatureItem(
          icon: Icons.alt_route_rounded,
          title: 'Traffic Corridor Coordination',
          description: 'Synchronized route clearing across municipal grids for verified emergency units.',
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          icon: Icons.local_hospital_rounded,
          title: 'Direct Trauma Bay Readiness',
          description: 'Live ETA telemetry and patient vital streams straight to receiving trauma centers.',
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          icon: Icons.radar_rounded,
          title: 'Citizen Yield Navigation',
          description: 'In-path radar perimeter alerting surrounding commuters to yield corridors safely.',
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppDecorations.skeuomorphicRaised(
        isDarkSurface: false,
        radius: 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: AppDecorations.iconMedallion(size: 38, isDark: true),
            child: Icon(icon, color: AppColors.warmPeach, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontHeading,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepViolet,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: AppTypography.fontBody,
                    fontSize: 12,
                    color: AppColors.deepViolet.withValues(alpha: 0.72),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBrandingHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: AppDecorations.iconMedallion(size: 64, isDark: true),
          child: const Icon(
            Icons.emergency_share_rounded,
            color: AppColors.warmPeach,
            size: 32,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'GREEN CORRIDOR',
          style: TextStyle(
            fontFamily: AppTypography.fontHeading,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.deepViolet,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'EMERGENCY LOGISTICS PORTAL',
          style: TextStyle(
            fontFamily: AppTypography.fontBody,
            fontSize: 12,
            color: AppColors.mutedBerry,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: AppDecorations.skeuomorphicRaised(
        isDarkSurface: false,
        radius: 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Sign In to Console',
            style: TextStyle(
              fontFamily: AppTypography.fontHeading,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.deepViolet,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter authorized operational credentials to access your facility or dispatch interface.',
            style: TextStyle(
              fontFamily: AppTypography.fontBody,
              fontSize: 13,
              color: AppColors.deepViolet.withValues(alpha: 0.75),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),

          // Email Input with skeuomorphic inset feel
          Text(
            'WORK EMAIL ADDRESS',
            style: TextStyle(
              fontFamily: AppTypography.fontBody,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.deepViolet,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: const TextStyle(
              fontFamily: AppTypography.fontBody,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.deepViolet,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFFAF7F0),
              hintText: "admin@hospital.org",
              hintStyle: TextStyle(
                fontFamily: AppTypography.fontBody,
                color: AppColors.deepViolet.withValues(alpha: 0.45),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.alternate_email_rounded,
                color: AppColors.mutedBerry,
                size: 20,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.warmPeach.withValues(alpha: 0.6), width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.deepViolet, width: 2.0),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Password Input
          Text(
            'PASSWORD',
            style: TextStyle(
              fontFamily: AppTypography.fontBody,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.deepViolet,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => loginUser(),
            style: const TextStyle(
              fontFamily: AppTypography.fontBody,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.deepViolet,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFFAF7F0),
              hintText: "••••••••••••",
              hintStyle: TextStyle(
                fontFamily: AppTypography.fontBody,
                color: AppColors.deepViolet.withValues(alpha: 0.45),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.mutedBerry,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.mutedBerry,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.warmPeach.withValues(alpha: 0.6), width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.deepViolet, width: 2.0),
              ),
            ),
          ),
          const SizedBox(height: 10),

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
                foregroundColor: AppColors.deepViolet,
              ),
              child: const Text(
                "Forgot password?",
                style: TextStyle(
                  fontFamily: AppTypography.fontBody,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepViolet,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Tactile Primary Button
          TactileButton(
            text: "Access Operations Console",
            icon: Icons.arrow_forward_rounded,
            variant: TactileButtonVariant.primary,
            isLoading: isLoading,
            height: 52,
            onPressed: isLoading ? null : loginUser,
          ),
          const SizedBox(height: 24),

          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.warmPeach.withValues(alpha: 0.6))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  "Public Commuter Navigation",
                  style: TextStyle(
                    fontFamily: AppTypography.fontBody,
                    color: AppColors.deepViolet.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppColors.warmPeach.withValues(alpha: 0.6))),
            ],
          ),
          const SizedBox(height: 18),

          // Direct Citizen Radar Button (Tactile Secondary)
          TactileButton(
            text: "Open Live Citizen Radar",
            icon: Icons.radar_rounded,
            variant: TactileButtonVariant.secondary,
            height: 48,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CitizenScreen()),
              );
            },
          ),
          const SizedBox(height: 22),

          // Register Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Need hospital facility onboarding? ",
                style: TextStyle(
                  fontFamily: AppTypography.fontBody,
                  fontSize: 13,
                  color: AppColors.deepViolet.withValues(alpha: 0.75),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text(
                  "Register Facility",
                  style: TextStyle(
                    fontFamily: AppTypography.fontBody,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepViolet,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.deepViolet,
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