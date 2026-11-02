import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../widgets/tactile_button.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final addressController = TextEditingController();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();

  String selectedRole = "Hospital Admin";
  bool isLoading = false;
  bool isLocating = false;
  bool obscurePassword = true;

  Future<void> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.navy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.sky, width: 1.5),
          ),
          content: const Text(
            "Please enable location services on your device",
            style: TextStyle(
              fontFamily: AppTypography.fontBody,
              color: AppColors.cream,
            ),
          ),
        ),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.navyDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.sky, width: 1.5),
          ),
          content: const Text(
            "Location permission denied. Please allow GPS access.",
            style: TextStyle(
              fontFamily: AppTypography.fontBody,
              color: AppColors.cream,
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      isLocating = true;
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      );
      latitudeController.text = position.latitude.toStringAsFixed(6);
      longitudeController.text = position.longitude.toStringAsFixed(6);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.navy,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.sky, width: 1.5),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.sky, size: 20),
                const SizedBox(width: 10),
                Text(
                  "GPS Locked: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}",
                  style: const TextStyle(
                    fontFamily: AppTypography.fontBody,
                    color: AppColors.cream,
                  ),
                ),
              ],
            ),
          ),
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
          content: Text(
            "Failed to lock GPS coordinates: $e",
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
          isLocating = false;
        });
      }
    }
  }

  Future<void> registerUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.navy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.sky, width: 1.5),
          ),
          content: const Text(
            "Please fill in all required credentials.",
            style: TextStyle(
              fontFamily: AppTypography.fontBody,
              color: AppColors.cream,
            ),
          ),
        ),
      );
      return;
    }

    if (selectedRole == "Hospital Admin") {
      if (addressController.text.trim().isEmpty ||
          latitudeController.text.trim().isEmpty ||
          longitudeController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.navyDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.sky, width: 1.5),
            ),
            content: const Text(
              "Hospital registration requires facility address and GPS coordinates.",
              style: TextStyle(
                fontFamily: AppTypography.fontBody,
                color: AppColors.cream,
              ),
            ),
          ),
        );
        return;
      }

      if (double.tryParse(latitudeController.text.trim()) == null ||
          double.tryParse(longitudeController.text.trim()) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.navyDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.sky, width: 1.5),
            ),
            content: const Text(
              "Latitude and Longitude must be valid numerical coordinates.",
              style: TextStyle(
                fontFamily: AppTypography.fontBody,
                color: AppColors.cream,
              ),
            ),
          ),
        );
        return;
      }
    }

    try {
      setState(() {
        isLoading = true;
      });

      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final userId = authResponse.user?.id;
      if (userId == null) {
        throw Exception("Sign up failed. Please check email format or credentials.");
      }

      String? hospitalCode;

      if (selectedRole == "Hospital Admin") {
        final words = name
            .split(' ')
            .where((w) => w.isNotEmpty)
            .toList();

        String prefix;
        if (words.length == 1) {
          prefix = words[0]
              .substring(0, min(3, words[0].length))
              .toUpperCase()
              .padRight(3, 'X');
        } else if (words.length == 2) {
          prefix = words[0].substring(0, min(2, words[0].length)).toUpperCase() +
              words[1][0].toUpperCase();
        } else {
          prefix = words[0][0].toUpperCase() +
              words[1][0].toUpperCase() +
              words[2][0].toUpperCase();
        }

        final hospitals = await Supabase.instance.client
            .from('users')
            .select('id')
            .eq('role', 'Hospital Admin');

        final nextNumber = hospitals.length + 1;
        hospitalCode = '$prefix${nextNumber.toString().padLeft(3, '0')}';
      }

      await Supabase.instance.client.from('users').insert({
        'id': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'role': selectedRole,
        'hospital_code': hospitalCode,
        'address': selectedRole == "Hospital Admin"
            ? addressController.text.trim()
            : null,
        'latitude': selectedRole == "Hospital Admin"
            ? double.tryParse(latitudeController.text.trim())
            : null,
        'longitude': selectedRole == "Hospital Admin"
            ? double.tryParse(longitudeController.text.trim())
            : null,
      });

      if (!mounted) return;
      final String successMsg = selectedRole == "Hospital Admin"
          ? "Facility account created (Code: $hospitalCode)! Please sign in."
          : "Citizen account registered successfully! Please sign in.";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.navy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.sky, width: 1.5),
          ),
          content: Text(
            successMsg,
            style: const TextStyle(
              fontFamily: AppTypography.fontBody,
              color: AppColors.cream,
            ),
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
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
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    addressController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;
    final isHospital = selectedRole == "Hospital Admin";

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Ambient soft lighting (Warm Peach & Soft Ivory over white)
          Positioned(
            top: -100,
            right: -80,
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
            left: -80,
            child: Container(
              width: 600,
              height: 600,
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

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 48 : 20,
                  vertical: 36,
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1140),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left branding panel
                            Expanded(
                              flex: 5,
                              child: _buildBrandingPanel(),
                            ),
                            const SizedBox(width: 48),
                            // Right form panel
                            Expanded(
                              flex: 6,
                              child: _buildRegistrationCard(isHospital),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildMobileHeader(),
                            const SizedBox(height: 24),
                            _buildRegistrationCard(isHospital),
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

  Widget _buildMobileHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navy),
              onPressed: () => Navigator.maybePop(context),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.sky, width: 1.2),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hub_rounded, size: 14, color: AppColors.sky),
                  SizedBox(width: 6),
                  Text(
                    "Network Portal",
                    style: TextStyle(
                      fontFamily: AppTypography.fontHeading,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.cream,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: AppDecorations.iconMedallion(size: 48),
              child: const Icon(Icons.emergency_share_rounded, color: AppColors.sky, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              "GREEN CORRIDOR",
              style: TextStyle(
                fontFamily: AppTypography.fontHeading,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.navy,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBrandingPanel() {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: AppDecorations.skeuomorphicRaised(
        isDarkSurface: false,
        radius: 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back to login button
          InkWell(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.mutedBerry),
                  SizedBox(width: 6),
                  Text(
                    "Back to Sign In",
                    style: TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepViolet,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Logo & Name
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
                    "GREEN CORRIDOR",
                    style: TextStyle(
                      fontFamily: AppTypography.fontHeading,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.deepViolet,
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    "TRAFFIC PREEMPTION SYSTEM",
                    style: TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mutedBerry,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          const Text(
            "Onboard Your Facility to the Live Corridor",
            style: TextStyle(
              fontFamily: AppTypography.fontHeading,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.deepViolet,
              letterSpacing: -0.4,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Connect your trauma center or join as a citizen participant. Enable coordinated route clearing and critical medical transit workflows.",
            style: TextStyle(
              fontFamily: AppTypography.fontBody,
              fontSize: 14,
              color: AppColors.deepViolet.withValues(alpha: 0.78),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 32),

          _buildFeatureRow(
            icon: Icons.local_hospital_rounded,
            title: "Hospital Command Network",
            desc: "Register facility coordinates to trigger green waves and monitor incoming emergency transports.",
          ),
          const SizedBox(height: 18),
          _buildFeatureRow(
            icon: Icons.radar_rounded,
            title: "Citizen Siren Radar",
            desc: "Commuters receive real-time proximity alerts to clear emergency lanes safely ahead of time.",
          ),
          const SizedBox(height: 18),
          _buildFeatureRow(
            icon: Icons.verified_user_rounded,
            title: "Institutional Verification",
            desc: "Role-based verification with secure telemetry logged for municipal traffic authority oversight.",
          ),

          const SizedBox(height: 32),
          Divider(color: AppColors.warmPeach.withValues(alpha: 0.6), height: 1),
          const SizedBox(height: 20),

          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.mutedBerry,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Operational Telemetry Active • Low-Latency Grid",
                style: TextStyle(
                  fontFamily: AppTypography.fontBody,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepViolet.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: AppDecorations.iconMedallion(size: 40, isDark: true),
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
                desc,
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
    );
  }

  Widget _buildRegistrationCard(bool isHospital) {
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
            "Create Account",
            style: TextStyle(
              fontFamily: AppTypography.fontHeading,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.deepViolet,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Select your role to join the coordinated emergency corridor grid.",
            style: TextStyle(
              fontFamily: AppTypography.fontBody,
              fontSize: 13,
              color: AppColors.deepViolet.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 24),

          // Role selection 3D cards
          Row(
            children: [
              Expanded(
                child: _roleCard(
                  title: "Hospital Admin",
                  subtitle: "Dispatch fleet & trauma triage",
                  icon: Icons.local_hospital_rounded,
                  isSelected: isHospital,
                  onTap: () => setState(() => selectedRole = "Hospital Admin"),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _roleCard(
                  title: "Citizen",
                  subtitle: "Radar siren & yield routing",
                  icon: Icons.person_rounded,
                  isSelected: !isHospital,
                  onTap: () => setState(() => selectedRole = "Citizen"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Driver notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: AppDecorations.skeuomorphicInset(radius: 12),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 16, color: AppColors.mutedBerry),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Ambulance drivers are provisioned directly by hospital facilities. Drivers do not self-register.",
                    style: TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 12,
                      color: AppColors.deepViolet.withValues(alpha: 0.75),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Name field
          _inputField(
            controller: nameController,
            label: isHospital ? "HOSPITAL / FACILITY NAME" : "FULL NAME",
            hint: isHospital ? "e.g. Apollo Multi-Speciality Hospital" : "e.g. Rahul Sharma",
            icon: isHospital ? Icons.domain_rounded : Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),

          // Email field
          _inputField(
            controller: emailController,
            label: "EMAIL ADDRESS",
            hint: isHospital ? "dispatch@apollo.org" : "user@domain.com",
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // Phone field
          _inputField(
            controller: phoneController,
            label: "CONTACT PHONE NUMBER",
            hint: "+91 98765 43210",
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          // Password field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "PASSWORD",
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
                      obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.mutedBerry,
                      size: 20,
                    ),
                    onPressed: () => setState(() => obscurePassword = !obscurePassword),
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
            ],
          ),

          // Hospital-specific fields
          if (isHospital) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppDecorations.skeuomorphicInset(radius: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.pin_drop_rounded, size: 20, color: AppColors.deepViolet),
                      SizedBox(width: 8),
                      Text(
                        "Facility Geolocation Coordinates",
                        style: TextStyle(
                          fontFamily: AppTypography.fontHeading,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepViolet,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Accurate coordinates enable routing green waves directly to your emergency trauma bay.",
                    style: TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 12,
                      color: AppColors.deepViolet.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: addressController,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepViolet,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "Street, Area, City, PIN code",
                      labelText: "Complete Hospital Address",
                      labelStyle: const TextStyle(
                        fontFamily: AppTypography.fontBody,
                        color: AppColors.deepViolet,
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(Icons.place_outlined, color: AppColors.mutedBerry, size: 20),
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
                  const SizedBox(height: 14),

                  TactileButton(
                    text: isLocating ? "Acquiring GPS Position..." : "Fetch Current GPS Coordinates",
                    icon: Icons.my_location_rounded,
                    variant: TactileButtonVariant.secondary,
                    isLoading: isLocating,
                    height: 48,
                    onPressed: isLocating ? null : getCurrentLocation,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: latitudeController,
                          readOnly: true,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontBody,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.deepViolet,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            labelText: "Latitude",
                            labelStyle: const TextStyle(
                              fontFamily: AppTypography.fontBody,
                              color: AppColors.deepViolet,
                              fontSize: 11,
                            ),
                            prefixIcon: const Icon(Icons.north_rounded, size: 16, color: AppColors.mutedBerry),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.warmPeach.withValues(alpha: 0.6), width: 1.2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.deepViolet, width: 2.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: longitudeController,
                          readOnly: true,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontBody,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.deepViolet,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            labelText: "Longitude",
                            labelStyle: const TextStyle(
                              fontFamily: AppTypography.fontBody,
                              color: AppColors.deepViolet,
                              fontSize: 11,
                            ),
                            prefixIcon: const Icon(Icons.east_rounded, size: 16, color: AppColors.mutedBerry),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.warmPeach.withValues(alpha: 0.6), width: 1.2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.deepViolet, width: 2.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Submit tactile button
          TactileButton(
            text: isHospital ? "REGISTER HOSPITAL FACILITY" : "JOIN AS CITIZEN",
            icon: Icons.arrow_forward_rounded,
            variant: TactileButtonVariant.primary,
            isLoading: isLoading,
            height: 52,
            onPressed: isLoading ? null : registerUser,
          ),
          const SizedBox(height: 22),

          // Sign In Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Already registered on the network?",
                style: TextStyle(
                  fontFamily: AppTypography.fontBody,
                  fontSize: 13,
                  color: AppColors.deepViolet.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text(
                  "Sign In",
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

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTypography.fontBody,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.deepViolet,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontFamily: AppTypography.fontBody,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.deepViolet,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFFAF7F0),
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: AppTypography.fontBody,
              color: AppColors.deepViolet.withValues(alpha: 0.45),
              fontSize: 13,
            ),
            prefixIcon: Icon(icon, color: AppColors.mutedBerry, size: 20),
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
      ],
    );
  }

  Widget _roleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: isSelected
            ? AppDecorations.skeuomorphicRaised(
                isDarkSurface: true,
                radius: 18,
              )
            : AppDecorations.skeuomorphicRaised(
                isDarkSurface: false,
                radius: 18,
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.deepVioletDark : const Color(0xFFF3ECE0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.warmPeach.withValues(alpha: 0.6) : AppColors.warmPeach.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? AppColors.warmPeach : AppColors.deepViolet,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.warmPeach)
                else
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.warmPeach, width: 1.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTypography.fontHeading,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isSelected ? AppColors.softIvory : AppColors.deepViolet,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: AppTypography.fontBody,
                fontSize: 11,
                color: isSelected ? AppColors.warmPeach : AppColors.deepViolet.withValues(alpha: 0.7),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}