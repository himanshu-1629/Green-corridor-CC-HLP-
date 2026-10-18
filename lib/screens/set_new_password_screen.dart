import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool obscure1 = true;
  bool obscure2 = true;

  @override
  void initState() {
    super.initState();
    _handleRecoveryLink();
  }

  Future<void> _handleRecoveryLink() async {
    try {
      final uri = Uri.base;
      final code = uri.queryParameters['code'];

      if (code != null) {
        await Supabase.instance.client.auth.exchangeCodeForSession(code);
      }
    } catch (e) {
      debugPrint("Recovery error: $e");
    }
  }

  Future<void> savePassword() async {
    if (passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a new password")),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primary,
          content: Text("Passwords do not match"),
        ),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          password: passwordController.text.trim(),
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emerald,
          behavior: SnackBarBehavior.floating,
          content: Text("Password updated successfully! Please log in."),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          content: Text(e.toString()),
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
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Set New Password"),
        backgroundColor: AppColors.slate900,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(32),
            decoration: AppDecorations.cardElevated(radius: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.emeraldLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 36,
                      color: AppColors.emeraldDark,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Create New Password",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Choose a strong password to secure your Green Corridor account.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.slate500,
                  ),
                ),
                const SizedBox(height: 28),

                TextField(
                  controller: passwordController,
                  obscureText: obscure1,
                  decoration: AppDecorations.input(
                    labelText: "New Password",
                    hintText: "••••••••",
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.slate400),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure1 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20,
                        color: AppColors.slate400,
                      ),
                      onPressed: () => setState(() => obscure1 = !obscure1),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscure2,
                  decoration: AppDecorations.input(
                    labelText: "Confirm Password",
                    hintText: "••••••••",
                    prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20, color: AppColors.slate400),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure2 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20,
                        color: AppColors.slate400,
                      ),
                      onPressed: () => setState(() => obscure2 = !obscure2),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppGradients.emergency,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
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
                    onPressed: isLoading ? null : savePassword,
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
                            "Update Password",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
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