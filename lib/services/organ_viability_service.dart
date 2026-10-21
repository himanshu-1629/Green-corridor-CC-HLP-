import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Clinical specifications for organ preservation and Cold Ischemia Time (CIT).
class OrganCITSpec {
  final String name;
  final double maxCitHours;
  final double criticalCitHours;
  final double minOptimalTemp;
  final double maxOptimalTemp;
  final String preservationMethod;
  final IconData icon;

  const OrganCITSpec({
    required this.name,
    required this.maxCitHours,
    required this.criticalCitHours,
    required this.minOptimalTemp,
    required this.maxOptimalTemp,
    required this.preservationMethod,
    required this.icon,
  });
}

class OrganViabilitySnapshot {
  final String organName;
  final String containerId;
  final DateTime harvestTime;
  final Duration elapsed;
  final Duration remaining;
  final double citProgress; // 0.0 (fresh) to 1.0 (exhausted)
  final double viabilityPercentage; // 0.0 to 100.0%
  final String statusLabel;
  final Color statusColor;
  final double internalTempC;
  final int perfusionPressureMmHg;
  final int containerBatteryPercent;
  final bool isAirlockSealed;
  final String clinicalRecommendation;

  const OrganViabilitySnapshot({
    required this.organName,
    required this.containerId,
    required this.harvestTime,
    required this.elapsed,
    required this.remaining,
    required this.citProgress,
    required this.viabilityPercentage,
    required this.statusLabel,
    required this.statusColor,
    required this.internalTempC,
    required this.perfusionPressureMmHg,
    required this.containerBatteryPercent,
    required this.isAirlockSealed,
    required this.clinicalRecommendation,
  });
}

class OrganViabilityService {
  static const Map<String, OrganCITSpec> _specs = {
    'Heart': OrganCITSpec(
      name: 'Heart',
      maxCitHours: 4.0,
      criticalCitHours: 3.0,
      minOptimalTemp: 2.0,
      maxOptimalTemp: 4.0,
      preservationMethod: 'Hypothermic Machine Perfusion (OCS)',
      icon: Icons.favorite_rounded,
    ),
    'Lungs': OrganCITSpec(
      name: 'Lungs',
      maxCitHours: 6.0,
      criticalCitHours: 5.0,
      minOptimalTemp: 4.0,
      maxOptimalTemp: 8.0,
      preservationMethod: 'Ex-Vivo Lung Perfusion (EVLP)',
      icon: Icons.air_rounded,
    ),
    'Liver': OrganCITSpec(
      name: 'Liver',
      maxCitHours: 10.0,
      criticalCitHours: 8.0,
      minOptimalTemp: 2.0,
      maxOptimalTemp: 4.0,
      preservationMethod: 'Hypothermic Oxygenated Perfusion (HOPE)',
      icon: Icons.water_drop_rounded,
    ),
    'Kidney': OrganCITSpec(
      name: 'Kidney',
      maxCitHours: 24.0,
      criticalCitHours: 18.0,
      minOptimalTemp: 2.0,
      maxOptimalTemp: 4.0,
      preservationMethod: 'Pulsatile Machine Perfusion (PMP)',
      icon: Icons.grain_rounded,
    ),
    'Pancreas': OrganCITSpec(
      name: 'Pancreas',
      maxCitHours: 12.0,
      criticalCitHours: 10.0,
      minOptimalTemp: 2.0,
      maxOptimalTemp: 4.0,
      preservationMethod: 'Static Cold Storage with Two-Layer Method',
      icon: Icons.health_and_safety_rounded,
    ),
    'Emergency Trauma': OrganCITSpec(
      name: 'Trauma Emergency',
      maxCitHours: 1.0, // Golden Hour
      criticalCitHours: 0.75,
      minOptimalTemp: 36.5,
      maxOptimalTemp: 37.5,
      preservationMethod: 'Active Resuscitation & Transit Stabilization',
      icon: Icons.emergency_rounded,
    ),
  };

  /// Determines the closest organ spec based on patient_name or mission type.
  static OrganCITSpec getSpec(String? rawType) {
    if (rawType == null || rawType.isEmpty) {
      return _specs['Heart']!;
    }
    final lower = rawType.toLowerCase();
    if (lower.contains('heart')) return _specs['Heart']!;
    if (lower.contains('lung')) return _specs['Lungs']!;
    if (lower.contains('liver')) return _specs['Liver']!;
    if (lower.contains('kidney')) return _specs['Kidney']!;
    if (lower.contains('pancrea')) return _specs['Pancreas']!;
    if (lower.contains('blood')) {
      return const OrganCITSpec(
        name: 'Blood Transport',
        maxCitHours: 6.0,
        criticalCitHours: 4.0,
        minOptimalTemp: 2.0,
        maxOptimalTemp: 6.0,
        preservationMethod: 'Active Cryo-Thermo Storage',
        icon: Icons.bloodtype_rounded,
      );
    }
    if (lower.contains('patient') || lower.contains('trauma') || lower.contains('urgent')) {
      return _specs['Emergency Trauma']!;
    }
    return _specs['Heart']!;
  }

  /// Calculates a real-time snapshot of cold ischemia time & cellular graft viability.
  static OrganViabilitySnapshot calculateSnapshot({
    required String? rawType,
    required DateTime harvestOrStartTime,
    String? containerCode,
    DateTime? currentTime,
  }) {
    final spec = getSpec(rawType);
    final now = currentTime ?? DateTime.now();

    // Elapsed duration since harvest/cross-clamp
    var elapsed = now.difference(harvestOrStartTime);
    if (elapsed.isNegative) elapsed = Duration.zero;

    final totalSeconds = (spec.maxCitHours * 3600).round();
    final elapsedSeconds = elapsed.inSeconds;
    final remainingSeconds = max(0, totalSeconds - elapsedSeconds);
    final remaining = Duration(seconds: remainingSeconds);

    // CIT progress from 0.0 (fresh) to 1.0 (exhausted)
    final progress = (elapsedSeconds / totalSeconds).clamp(0.0, 1.0);

    // Physiological viability degradation model
    // V(t) remains high (>90%) initially, then degrades exponentially near critical limit.
    final tRatio = elapsedSeconds / totalSeconds;
    double viability;
    if (tRatio <= 0.5) {
      viability = 100.0 - (tRatio * 15.0); // 100% -> 92.5%
    } else if (tRatio <= 0.8) {
      viability = 92.5 - ((tRatio - 0.5) / 0.3) * 22.5; // 92.5% -> 70%
    } else if (tRatio <= 1.0) {
      viability = 70.0 - ((tRatio - 0.8) / 0.2) * 35.0; // 70% -> 35%
    } else {
      viability = max(5.0, 35.0 - (tRatio - 1.0) * 50.0);
    }

    // Status classification
    String statusLabel;
    Color statusColor;
    String recommendation;

    if (viability >= 85.0) {
      statusLabel = 'OPTIMAL VIABILITY';
      statusColor = AppColors.emerald;
      recommendation = 'Graft cellular integrity exceptional. Proceed on designated corridor.';
    } else if (viability >= 70.0) {
      statusLabel = 'STABLE (TRANSIT CRITICAL)';
      statusColor = AppColors.amber;
      recommendation = 'Mild ischemic drift. Maintain uninhibited corridor velocity.';
    } else if (viability > 35.0) {
      statusLabel = 'HIGH ISCHEMIA RISK';
      statusColor = AppColors.primary;
      recommendation = 'Critical CIT window approaching! Alert recipient surgical bay.';
    } else {
      statusLabel = 'GRAFT COMPROMISED';
      statusColor = const Color(0xFF7F1D1D);
      recommendation = 'Exceeded safe CIT threshold. Emergency perfusion assessment needed.';
    }

    // Deterministic subtle fluctuations for IoT telemetry
    final seed = elapsed.inSeconds ~/ 5;
    final tempWobble = (sin(seed * 0.4) * 0.3);
    final internalTemp = ((spec.minOptimalTemp + spec.maxOptimalTemp) / 2.0) + tempWobble;

    final pressureWobble = (cos(seed * 0.3) * 2).round();
    final perfusionPressure = 28 + pressureWobble;

    final battery = max(65, 99 - (elapsed.inHours * 3));
    final cid = containerCode ?? 'CRYO-${spec.name.toUpperCase().substring(0, min(4, spec.name.length))}-${(harvestOrStartTime.millisecondsSinceEpoch % 900) + 100}';

    return OrganViabilitySnapshot(
      organName: spec.name,
      containerId: cid,
      harvestTime: harvestOrStartTime,
      elapsed: elapsed,
      remaining: remaining,
      citProgress: progress,
      viabilityPercentage: viability,
      statusLabel: statusLabel,
      statusColor: statusColor,
      internalTempC: double.parse(internalTemp.toStringAsFixed(1)),
      perfusionPressureMmHg: perfusionPressure,
      containerBatteryPercent: battery,
      isAirlockSealed: true,
      clinicalRecommendation: recommendation,
    );
  }

  /// Formats duration as HH:MM:SS
  static String formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
