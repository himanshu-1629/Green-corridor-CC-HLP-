import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class ManageDriversScreen extends StatefulWidget {
  const ManageDriversScreen({super.key});

  @override
  State<ManageDriversScreen> createState() => _ManageDriversScreenState();
}

class _ManageDriversScreenState extends State<ManageDriversScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final licenseController = TextEditingController();
  final searchController = TextEditingController();

  bool isDeleting = false;
  bool isAdding = false;
  bool isLoading = true;
  List<Map<String, dynamic>> drivers = [];
  List<Map<String, dynamic>> filteredDrivers = [];

  @override
  void initState() {
    super.initState();
    loadDrivers();
  }

  Future<void> loadDrivers() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('role', 'Driver')
          .eq('hospital_id', userId)
          .order('driver_sequence', ascending: true);

      if (mounted) {
        setState(() {
          drivers = List<Map<String, dynamic>>.from(data);
          filteredDrivers = drivers;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading drivers: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _filterDrivers(String query) {
    if (query.isEmpty) {
      setState(() => filteredDrivers = drivers);
      return;
    }

    final lower = query.toLowerCase();
    setState(() {
      filteredDrivers = drivers.where((drv) {
        final name = drv['name']?.toString().toLowerCase() ?? '';
        final email = drv['email']?.toString().toLowerCase() ?? '';
        final code = drv['driver_code']?.toString().toLowerCase() ?? '';
        final license = drv['license_number']?.toString().toLowerCase() ?? '';
        return name.contains(lower) || email.contains(lower) || code.contains(lower) || license.contains(lower);
      }).toList();
    });
  }

  Future<void> deleteDriver(Map<String, dynamic> driver) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Remove Driver?", style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text("Are you sure you want to remove ${driver['name']} from your emergency personnel roster?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Remove Driver"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => isDeleting = true);
      try {
        await Supabase.instance.client.functions.invoke(
          'delete-driver',
          body: {'driverId': driver['id']},
        );
        await loadDrivers();
      } catch (e) {
        debugPrint("Error deleting driver: $e");
      } finally {
        if (mounted) setState(() => isDeleting = false);
      }
    }
  }

  void _showAddDriverDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              title: const Text(
                "Register Transport Driver",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: AppDecorations.input(
                        labelText: "Driver Full Name",
                        hintText: "e.g. Rajesh Kumar",
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.slate400, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: AppDecorations.input(
                        labelText: "Driver Email (Login Credential)",
                        hintText: "rajesh@hospital.com",
                        prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppColors.slate400, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: AppDecorations.input(
                        labelText: "Driver Phone Number",
                        hintText: "+91 98765 43210",
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.slate400, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: licenseController,
                      decoration: AppDecorations.input(
                        labelText: "Commercial Driving License",
                        hintText: "MH-12-2023-0098765",
                        prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.slate400, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    nameController.clear();
                    emailController.clear();
                    phoneController.clear();
                    licenseController.clear();
                    Navigator.pop(dialogCtx);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isAdding
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty ||
                              emailController.text.trim().isEmpty ||
                              phoneController.text.trim().isEmpty) {
                            return;
                          }

                          setDialogState(() => isAdding = true);

                          try {
                            final userId = Supabase.instance.client.auth.currentUser!.id;

                            await Supabase.instance.client.functions.invoke(
                              'create-driver',
                              body: {
                                'name': nameController.text.trim(),
                                'email': emailController.text.trim(),
                                'phone': phoneController.text.trim(),
                                'licenseNumber': licenseController.text.trim(),
                                'hospitalId': userId,
                              },
                            );

                            nameController.clear();
                            emailController.clear();
                            phoneController.clear();
                            licenseController.clear();

                            if (!mounted || !dialogCtx.mounted) return;
                            Navigator.pop(dialogCtx);
                            await loadDrivers();
                          } catch (e) {
                            debugPrint("Error creating driver: $e");
                          } finally {
                            if (mounted) setDialogState(() => isAdding = false);
                          }
                        },
                  child: isAdding
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text("Onboard Driver"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    licenseController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            titleSpacing: 20,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.slate900,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: AppColors.slate200, height: 1),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.badge_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Emergency Drivers",
                      style: AppFonts.neueMontreal(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      "Hospital Certified Pilot Roster",
                      style: AppFonts.neueMontreal(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: "Refresh Roster",
                icon: const Icon(Icons.sync_rounded, color: AppColors.slate700),
                onPressed: loadDrivers,
              ),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            elevation: 4,
            onPressed: _showAddDriverDialog,
            icon: const Icon(Icons.person_add_rounded, color: Colors.white),
            label: Text(
              "Add Driver",
              style: AppFonts.neueMontreal(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      // Search Field
                      TextField(
                        controller: searchController,
                        onChanged: _filterDrivers,
                        decoration: AppDecorations.input(
                          labelText: "Search Driver Roster",
                          hintText: "Search by name, email, code or license...",
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.slate400),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    searchController.clear();
                                    _filterDrivers("");
                                  },
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        "Registered Personnel (${filteredDrivers.length})",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Expanded(
                        child: filteredDrivers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.person_outline_rounded, size: 48, color: AppColors.slate400),
                                    SizedBox(height: 12),
                                    Text(
                                      "No drivers registered yet",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.slate700),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: loadDrivers,
                                color: AppColors.primary,
                                child: ListView.separated(
                                  itemCount: filteredDrivers.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final driver = filteredDrivers[index];
                                    final isAvailable = driver['is_available'] == true;
                                    final code = driver['driver_code'] ?? "DRV";

                                    return Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: AppDecorations.card(radius: 18),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isAvailable ? AppColors.emeraldLight : AppColors.primaryLight,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.person_pin_rounded,
                                              color: isAvailable ? AppColors.emeraldDark : AppColors.primary,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      driver["name"] ?? "Driver",
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w800,
                                                        color: AppColors.slate900,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.slate100,
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        code,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w700,
                                                          color: AppColors.slate700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.phone_outlined, size: 13, color: AppColors.slate400),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      driver["phone"] ?? "No phone",
                                                      style: const TextStyle(fontSize: 13, color: AppColors.slate500),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    const Icon(Icons.badge_outlined, size: 13, color: AppColors.slate400),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        driver["license_number"] ?? "No license",
                                                        style: const TextStyle(fontSize: 13, color: AppColors.slate500),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isAvailable ? AppColors.emeraldLight : AppColors.warningLight,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              isAvailable ? "Available" : "On Mission",
                                              style: TextStyle(
                                                color: isAvailable ? AppColors.emeraldDark : AppColors.warning,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.slate400, size: 20),
                                            onPressed: () => deleteDriver(driver),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ),
        if (isDeleting)
          Container(
            color: AppColors.navyDark.withValues(alpha: 0.45),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.sky),
              ),
            ),
          ),
      ],
    );
  }
}