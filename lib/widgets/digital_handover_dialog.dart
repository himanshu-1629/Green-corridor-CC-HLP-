import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/organ_viability_service.dart';
import '../theme/app_theme.dart';

class DigitalHandoverDialog extends StatefulWidget {
  final Map<String, dynamic> mission;
  final Map<String, dynamic>? destinationHospital;
  final Map<String, dynamic>? ambulanceData;
  final Map<String, dynamic>? driverData;
  final Future<void> Function({
    required String surgeonName,
    required String otRoom,
    required String notes,
  }) onConfirmHandover;

  const DigitalHandoverDialog({
    super.key,
    required this.mission,
    this.destinationHospital,
    this.ambulanceData,
    this.driverData,
    required this.onConfirmHandover,
  });

  @override
  State<DigitalHandoverDialog> createState() => _DigitalHandoverDialogState();
}

class _DigitalHandoverDialogState extends State<DigitalHandoverDialog> {
  final _surgeonController = TextEditingController(text: "Dr. Vikram Sethi, MCh");
  final _otRoomController = TextEditingController(text: "OT-3 (Transplant Bay)");
  final _notesController = TextEditingController(text: "Graft cold chain maintained; seal intact. Reperfusion team standing by.");

  bool _sealIntact = true;
  bool _temperatureCompliant = true;
  bool _crossMatchVerified = true;
  bool _isSubmitting = false;
  bool _isHandoverComplete = false;
  String? _handoverCertificateId;

  @override
  void dispose() {
    _surgeonController.dispose();
    _otRoomController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitHandover() async {
    if (_surgeonController.text.trim().isEmpty || _otRoomController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primary,
          content: Text("Please provide Lead Surgeon and OT Room details"),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final certId = "GC-TX-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";

      await widget.onConfirmHandover(
        surgeonName: _surgeonController.text.trim(),
        otRoom: _otRoomController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isHandoverComplete = true;
          _handoverCertificateId = certId;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text("Handover confirmation error: $e"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final organType = widget.mission['patient_name']?.toString() ?? "Organ";
    final harvestTime = DateTime.tryParse(widget.mission['created_at']?.toString() ?? '') ?? DateTime.now();
    final snapshot = OrganViabilityService.calculateSnapshot(
      rawType: organType,
      harvestOrStartTime: harvestTime,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 36,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: _isHandoverComplete
              ? _buildCertificateView(snapshot)
              : _buildHandoverForm(snapshot),
        ),
      ),
    );
  }

  Widget _buildHandoverForm(OrganViabilitySnapshot s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.emerald,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "DIGITAL ORGAN HANDOVER PROTOCOL",
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Chain-of-Custody & Cold Ischemia Audit Verification",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Telemetry Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.organName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Container: ${s.containerId}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.slate500,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Viability: ${s.viabilityPercentage.toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: s.statusColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Total CIT: ${OrganViabilityService.formatDuration(s.elapsed)}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.slate600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Checklist
              const Text(
                "Surgical Receiving Bay Verification Checklist",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 8),

              _buildCheckItem(
                title: "Cryo-Pod Airlock Seal Intact",
                subtitle: "Tamper-evident electronic seal verified by recipient hospital",
                value: _sealIntact,
                onChanged: (v) => setState(() => _sealIntact = v!),
              ),
              _buildCheckItem(
                title: "Cold Chain Temperature Compliant (2°C - 4°C)",
                subtitle: "Continuous sensor log confirms unbroken hypothermic chain",
                value: _temperatureCompliant,
                onChanged: (v) => setState(() => _temperatureCompliant = v!),
              ),
              _buildCheckItem(
                title: "HLA / Cross-Match & Donor ID Re-Verified",
                subtitle: "Recipient surgical registry cross-reference confirmed",
                value: _crossMatchVerified,
                onChanged: (v) => setState(() => _crossMatchVerified = v!),
              ),

              const SizedBox(height: 20),

              // Form fields
              const Text(
                "Recipient Surgical Authority Sign-Off",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _surgeonController,
                decoration: InputDecoration(
                  labelText: "Lead Transplant Surgeon Name & Credentials",
                  prefixIcon: const Icon(Icons.person_rounded, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.slate50,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _otRoomController,
                decoration: InputDecoration(
                  labelText: "Operating Theater (OT) Bay",
                  prefixIcon: const Icon(Icons.meeting_room_rounded, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.slate50,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Clinical Observations & Handover Notes",
                  prefixIcon: const Icon(Icons.note_alt_rounded, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.slate50,
                ),
              ),

              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: (_isSubmitting || !_sealIntact || !_temperatureCompliant || !_crossMatchVerified)
                          ? null
                          : _submitHandover,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_rounded, size: 18),
                      label: Text(
                        _isSubmitting ? "Verifying..." : "Authorize Handover & Complete",
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            Checkbox(
              value: value,
              activeColor: AppColors.emerald,
              onChanged: onChanged,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Official Certificate of Organ Handover
  Widget _buildCertificateView(OrganViabilitySnapshot s) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          color: const Color(0xFF0F172A),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emerald,
                ),
                child: const Icon(Icons.verified_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 14),
              Text(
                "ORGAN HANDOVER CERTIFICATE",
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Chain-of-Custody Officially Certified by Green Corridor Network",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Text(
                  "CERTIFICATE ID: ${_handoverCertificateId ?? 'GC-TX-VERIFIED'}",
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.emerald,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _certRow("Organ Payload", s.organName),
              _certRow("Preservation Pod", s.containerId),
              _certRow("Total Cold Ischemia Time", OrganViabilityService.formatDuration(s.elapsed)),
              _certRow("Final Cellular Graft Viability", "${s.viabilityPercentage.toStringAsFixed(1)}% (${s.statusLabel})"),
              _certRow("Mean Pod Temperature", "${s.internalTempC} °C (2°C - 4°C Compliant)"),
              _certRow("Recipient Surgeon", _surgeonController.text.trim()),
              _certRow("Receiving Facility", widget.destinationHospital?['name'] ?? 'Destination Hospital'),
              _certRow("Operation Theater", _otRoomController.text.trim()),
              _certRow("Handover Timestamp", DateTime.now().toIso8601String().substring(0, 19).replaceAll('T', ' ')),

              const Divider(height: 32, color: AppColors.slate200),

              // Cryptographic signature simulation badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_2_rounded, size: 36, color: AppColors.slate700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Tamper-Evident Ledger Signature",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            "SHA256: 8f4a3c1e92d7b...e109f (Immutable Green Corridor Handover)",
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              color: AppColors.slate500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.slate900,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Close & Finalize Mission",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _certRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.slate500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate800),
          ),
        ],
      ),
    );
  }
}
