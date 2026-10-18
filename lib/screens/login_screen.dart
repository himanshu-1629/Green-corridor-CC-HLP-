import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'forgot_password_screen.dart';
import 'driver_dashboard.dart';
import 'super_admin_dashboard.dart';
import 'hospital_dashboard.dart';
import 'register_screen.dart';
import 'citizen_screen.dart';

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
    try {
      setState(() {
        isLoading = true;
      });

      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
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
      } else if (role == "Super Admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const SuperAdminDashboard(),
          ),
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
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.toString().contains("Invalid")
                      ? "Invalid email or password"
                      : "Login failed. Please check your credentials.",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.all(36),
            decoration: AppDecorations.cardElevated(radius: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Brand Mark
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emergency_rounded,
                      size: 38,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Titles
                const Text(
                  "Green Corridor",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Emergency Medical Logistics Portal",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),

                // Email Input
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: AppDecorations.input(
                    labelText: "Email Address",
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

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      foregroundColor: AppColors.primary,
                    ),
                    child: const Text(
                      "Forgot password?",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Login Action Button
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppGradients.emergency,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: isLoading ? null : loginUser,
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            "Sign In to Operations",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
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
                        "New to platform?",
                        style: TextStyle(
                          color: AppColors.slate400,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.slate200)),
                  ],
                ),
                const SizedBox(height: 18),

                // Register Link Button
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.slate800,
                    side: const BorderSide(color: AppColors.slate200, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Register Hospital / Citizen",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}