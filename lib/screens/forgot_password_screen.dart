import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  bool isLoading = false;

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.navy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.sky, width: 1.5),
          ),
          content: const Text(
            "Please enter your email address",
            style: TextStyle(
              fontFamily: AppTypography.fontBody,
              color: AppColors.cream,
            ),
          ),
        ),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: "https://green-corridor-web.web.app",
      );

      if (!mounted) return;

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
              Icon(Icons.check_circle_rounded, color: AppColors.sky, size: 20),
              SizedBox(width: 10),
              Text(
                "Password reset link dispatched to your inbox.",
                style: TextStyle(
                  fontFamily: AppTypography.fontBody,
                  color: AppColors.cream,
                ),
              ),
            ],
          ),
        ),
      );

      Navigator.pop(context);
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
          content: Text(
            e.toString().replaceAll("Exception: ", ""),
            style: const TextStyle(
              fontFamily: AppTypography.fontBody,
              color: AppColors.cream,
            ),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text(
          "Password Recovery",
          style: TextStyle(
            fontFamily: AppTypography.fontHeading,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.cream,
          ),
        ),
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.cream,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppColors.sky, width: 1.5),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: AppColors.cream.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.sky, width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.12),
                        blurRadius: 32,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppDecorations.iconMedallion(size: 64),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            size: 32,
                            color: AppColors.sky,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Reset Account Access",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTypography.fontHeading,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.navy,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Enter the institutional or account email address associated with your Green Corridor profile to receive a recovery link.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTypography.fontBody,
                          fontSize: 13,
                          color: AppColors.navyMuted,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 28),

                      const Text(
                        "REGISTERED EMAIL ADDRESS",
                        style: TextStyle(
                          fontFamily: AppTypography.fontBody,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontBody,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.creamLight,
                          hintText: "admin@hospital.org",
                          hintStyle: TextStyle(
                            fontFamily: AppTypography.fontBody,
                            color: AppColors.navyMuted.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.alternate_email_rounded,
                            color: AppColors.navyLight,
                            size: 20,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: AppColors.sky.withValues(alpha: 0.6), width: 1.4),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.navy, width: 2.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 3D Sculpted Reset Button
                      Container(
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.navy.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            foregroundColor: AppColors.cream,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: AppColors.sky, width: 1.5),
                            ),
                          ),
                          onPressed: isLoading ? null : resetPassword,
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.sky),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.mark_email_read_rounded, color: AppColors.sky, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      "Send Password Recovery Link",
                                      style: TextStyle(
                                        fontFamily: AppTypography.fontHeading,
                                        color: AppColors.cream,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}