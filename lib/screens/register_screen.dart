import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
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
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text("Please enable location services on your device"),
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
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text("Location permission denied. Please allow GPS access."),
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
            backgroundColor: AppColors.emerald,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              "GPS Locked: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text("Failed to lock GPS coordinates: $e"),
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
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text("Please fill in all required credentials."),
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
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Text("Hospital registration requires facility address and GPS coordinates."),
          ),
        );
        return;
      }

      if (double.tryParse(latitudeController.text.trim()) == null ||
          double.tryParse(longitudeController.text.trim()) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Text("Latitude and Longitude must be valid numerical coordinates."),
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
          backgroundColor: AppColors.emerald,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(successMsg),
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
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(e.toString().replaceAll("Exception: ", "")),
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
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 48 : 20,
            vertical: 36,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1120),
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
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.slate700),
              onPressed: () => Navigator.maybePop(context),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.emeraldLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.emerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Network Portal",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.emeraldDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              "Green Corridor",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.slate900,
                letterSpacing: -0.5,
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
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
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.slate600),
                  const SizedBox(width: 6),
                  Text(
                    "Back to Sign In",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate600,
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
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emergency_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Green Corridor",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.slate900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    "Emergency Preemption System",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          Text(
            "Onboard Your Facility to the Live Corridor",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
              letterSpacing: -0.6,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Connect your trauma center or join as a citizen participant. Enable automated green-wave signal clearance and zero-delay critical organ transfers.",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.slate600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          _buildFeatureRow(
            icon: Icons.local_hospital_rounded,
            title: "Hospital Command Network",
            desc: "Register facility coordinates to trigger green waves and receive real-time ambulance ETA telemetry.",
            accentColor: AppColors.primary,
          ),
          const SizedBox(height: 20),
          _buildFeatureRow(
            icon: Icons.notifications_active_rounded,
            title: "Citizen Siren Radar",
            desc: "Citizens receive immediate proximity alerts and clear lane yield directions when ambulances approach.",
            accentColor: AppColors.emerald,
          ),
          const SizedBox(height: 20),
          _buildFeatureRow(
            icon: Icons.security_rounded,
            title: "Institutional Security",
            desc: "Role-based verification and tamper-proof telemetry logged for municipal traffic authority oversight.",
            accentColor: AppColors.info,
          ),

          const SizedBox(height: 36),
          const Divider(color: AppColors.slate200, height: 1),
          const SizedBox(height: 20),

          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.emerald,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Telemetry Gateway Online • Latency < 18ms",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate500,
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
    required Color accentColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accentColor, size: 20),
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
                desc,
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

  Widget _buildRegistrationCard(bool isHospital) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Create Account",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Select your profile type to register on the emergency grid",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.slate500,
            ),
          ),
          const SizedBox(height: 24),

          // Role selection cards (Hospital Admin, Citizen)
          Row(
            children: [
              Expanded(
                child: _roleCard(
                  title: "Hospital Admin",
                  subtitle: "Dispatch fleet & triage",
                  icon: Icons.local_hospital_rounded,
                  isSelected: isHospital,
                  accentColor: AppColors.primary,
                  onTap: () => setState(() => selectedRole = "Hospital Admin"),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _roleCard(
                  title: "Citizen",
                  subtitle: "Radar siren & alerts",
                  icon: Icons.person_rounded,
                  isSelected: !isHospital,
                  accentColor: AppColors.emerald,
                  onTap: () => setState(() => selectedRole = "Citizen"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Driver hospital-only provisioning notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 16, color: AppColors.slate500),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Ambulance drivers are registered exclusively by their hospital facility. Drivers do not self-register.",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.slate600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Name field
          TextField(
            controller: nameController,
            decoration: AppDecorations.input(
              labelText: isHospital ? "Hospital / Facility Name" : "Full Name",
              hintText: isHospital ? "e.g. Apollo Multi-Speciality Hospital" : "e.g. Rahul Sharma",
              prefixIcon: Icon(
                isHospital ? Icons.domain_rounded : Icons.person_outline_rounded,
                color: AppColors.slate400,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Email field
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: AppDecorations.input(
              labelText: "Email Address",
              hintText: isHospital ? "er.admin@apollo.org" : "user@domain.com",
              prefixIcon: const Icon(
                Icons.alternate_email_rounded,
                color: AppColors.slate400,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Phone field
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: AppDecorations.input(
              labelText: "Contact Phone Number",
              hintText: "+91 98765 43210",
              prefixIcon: const Icon(
                Icons.phone_outlined,
                color: AppColors.slate400,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Password field
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
                  obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.slate400,
                  size: 20,
                ),
                onPressed: () => setState(() => obscurePassword = !obscurePassword),
              ),
            ),
          ),

          // Hospital-specific fields
          if (isHospital) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pin_drop_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        "Hospital Geolocation Coordinates",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Accurate coordinates enable routing green waves directly to your trauma bay.",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.slate500,
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: addressController,
                    decoration: AppDecorations.input(
                      labelText: "Complete Hospital Address",
                      hintText: "Street, Area, City, PIN code",
                      prefixIcon: const Icon(Icons.place_outlined, color: AppColors.slate400, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),

                  InkWell(
                    onTap: isLocating ? null : getCurrentLocation,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isLocating)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(AppColors.emeraldDark),
                              ),
                            )
                          else
                            const Icon(Icons.my_location_rounded, size: 18, color: AppColors.emeraldDark),
                          const SizedBox(width: 8),
                          Text(
                            isLocating ? "Acquiring GPS Position..." : "Fetch Current GPS Coordinates",
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.emeraldDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: latitudeController,
                          readOnly: true,
                          decoration: AppDecorations.input(
                            labelText: "Latitude",
                            prefixIcon: const Icon(Icons.north_rounded, size: 16, color: AppColors.slate400),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: longitudeController,
                          readOnly: true,
                          decoration: AppDecorations.input(
                            labelText: "Longitude",
                            prefixIcon: const Icon(Icons.east_rounded, size: 16, color: AppColors.slate400),
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

          // Submit button
          Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: isHospital ? AppGradients.emergency : AppGradients.emerald,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (isHospital ? AppColors.primary : AppColors.emerald).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: isLoading ? null : registerUser,
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isHospital ? "REGISTER HOSPITAL FACILITY" : "JOIN AS CITIZEN",
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Sign In Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Already registered on the network?",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.slate600,
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
                child: Text(
                  "Sign In",
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

  Widget _roleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.slate200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
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
                    color: isSelected ? accentColor.withValues(alpha: 0.12) : AppColors.slate100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? accentColor : AppColors.slate600,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, size: 18, color: accentColor)
                else
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.slate300, width: 1.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isSelected ? AppColors.slate900 : AppColors.slate700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.slate500,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}