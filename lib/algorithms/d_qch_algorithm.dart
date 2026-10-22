import 'dart:math' as math;

/// ============================================================================
/// CC-HLP: Chance-Constrained Human-in-the-Loop Preemption Algorithm
/// 
/// Publication Model for IEEE Transactions on Intelligent Transportation Systems:
/// 1. Formally derived from Webster / Newell Macroscopic Traffic Flow Conservation.
/// 2. 5-Stage Conditional Driver Yielding Chain with Poisson Critical Gap Acceptance.
/// 3. Binomial Stochastic Residual Queue Modeling with (1 - \epsilon) Chance-Constrained Safety.
/// 4. NEMA TS2 / MUTCD Signal Transition Interlock Constraints.
/// ============================================================================

class CCHLPState {
  final double ambulanceSpeedMs;       // Instantaneous speed v_amb (m/s)
  final double ambulanceAcceleration;  // a_amb (m/s^2)
  final double distanceToJunctionM;    // d_k (meters)
  final int observedQueueCount;        // N_k (stationary vehicles in approach lane)
  final double appPenetrationRate;     // \rho_app \in [0, 1]
  final double adjacentLaneFlowVehS;   // q_adj (flow rate in target yielding lane, veh/s)
  final double saturationFlowRate;     // q_max (saturation departure flow, default 0.5 veh/s = 1800 veh/h)
  final double startupLostTimeSec;     // t_L (human reaction & startup loss, default 2.0s)
  final double conflictingPhaseElapsed;// g_elapsed (seconds elapsed in current green phase)
  final double conflictingPhaseMinGreen;// g_min (minimum green requirement, default 6.0s)

  const CCHLPState({
    required this.ambulanceSpeedMs,
    this.ambulanceAcceleration = 2.0,
    required this.distanceToJunctionM,
    required this.observedQueueCount,
    this.appPenetrationRate = 0.35,
    this.adjacentLaneFlowVehS = 0.25, // ~900 veh/h moderate traffic
    this.saturationFlowRate = 0.5,
    this.startupLostTimeSec = 2.0,
    this.conflictingPhaseElapsed = 12.0,
    this.conflictingPhaseMinGreen = 6.0,
  });
}

class CCHLPDecision {
  final bool shouldTriggerPreemption;
  final double estimatedTimeOfArrivalSec;
  final double clearanceTimeSec;
  final double transitionTimeSec;
  final double yieldProbability;
  final double criticalResidualQueue;
  final String statusRationale;

  const CCHLPDecision({
    required this.shouldTriggerPreemption,
    required this.estimatedTimeOfArrivalSec,
    required this.clearanceTimeSec,
    required this.transitionTimeSec,
    required this.yieldProbability,
    required this.criticalResidualQueue,
    required this.statusRationale,
  });
}

class CCHLPAlgorithm {
  // Calibrated Physical Constants (HCM 6th Edition & Literature Standards)
  static const double kCriticalLaneChangeGapSec = 3.5; // t_c (Highway Capacity Manual)
  static const double kDriverComplianceWillingness = 0.82; // \eta (Lidestam et al., 2020)
  static const double kNetworkDeliverySuccessRate = 0.96; // 1 - P_loss
  static const double kAcousticThresholdDistanceM = 300.0; // \sigma_audio
  static const double kYellowChangeIntervalSec = 3.5; // t_yellow (MUTCD / IRC)
  static const double kAllRedClearanceIntervalSec = 2.0; // t_all_red (MUTCD / IRC)
  static const double kZScore99Percent = 2.326; // z_{0.99} (99% confidence risk tolerance \epsilon = 0.01)

  /// 1. Macroscopic Webster/Newell Queue Clearance Time
  /// T_clear(N) = t_L + (N / q_max)
  static double computeWebsterClearanceTime({
    required double queueCount,
    double saturationFlowRate = 0.5,
    double startupLostTimeSec = 2.0,
  }) {
    if (queueCount <= 0) return 0.0;
    return startupLostTimeSec + (queueCount / saturationFlowRate);
  }

  /// 2. Five-Stage Conditional Driver Yielding Probability
  /// P(yield) = \rho_app * P_net * P_attention * \eta_compliance * P_gap
  static double computeConditionalYieldProbability({
    required double appPenetrationRate,
    required double distanceToAmbulanceM,
    required double adjacentLaneFlowVehS,
  }) {
    final rhoApp = appPenetrationRate.clamp(0.0, 1.0);
    final pNet = kNetworkDeliverySuccessRate;

    // Attention / Auditory Perception Decay Kernel: 1 - exp(- \sigma / (d + \epsilon))
    final pAttention = 1.0 - math.exp(-kAcousticThresholdDistanceM / (distanceToAmbulanceM + 1.0));

    // Willingness to comply:
    final pCompliance = kDriverComplianceWillingness;

    // Poisson Gap Feasibility: P(gap >= t_c) = exp(- q_adj * t_c)
    final pGap = math.exp(-adjacentLaneFlowVehS * kCriticalLaneChangeGapSec);

    final pYield = rhoApp * pNet * pAttention * pCompliance * pGap;
    return pYield.clamp(0.0, 1.0);
  }

  /// 3. Chance-Constrained Critical Residual Queue (1 - \epsilon = 99% Safety Guarantee)
  /// N_crit = E[N_rem] + z_{0.99} * sqrt(Var(N_rem))
  static double computeCriticalResidualQueue({
    required int observedQueueCount,
    required double yieldProbability,
    double zScore = kZScore99Percent,
  }) {
    if (observedQueueCount <= 0) return 0.0;

    final n = observedQueueCount.toDouble();
    final p = yieldProbability.clamp(0.0, 1.0);

    // Expected remaining blocking vehicles:
    final expectedResidual = n * (1.0 - p);

    // Binomial variance: Var = n * p * (1 - p)
    final binomialVariance = n * p * (1.0 - p);
    final stdDev = math.sqrt(math.max(0.0, binomialVariance));

    // Chance-constrained upper bound:
    final criticalQueue = expectedResidual + (zScore * stdDev);
    return criticalQueue.clamp(0.0, n);
  }

  /// 4. NEMA TS2 / MUTCD Phase Transition Safety Interlock
  /// T_transition = max(0, g_min - g_elapsed) + t_yellow + t_all_red
  static double computeTransitionSafetyDuration({
    required double conflictingPhaseElapsedSec,
    required double conflictingPhaseMinGreenSec,
  }) {
    final remainingMinGreen = math.max(0.0, conflictingPhaseMinGreenSec - conflictingPhaseElapsedSec);
    return remainingMinGreen + kYellowChangeIntervalSec + kAllRedClearanceIntervalSec;
  }

  /// 5. Trapezoidal Kinematic Arrival Time
  static double computeKinematicETA({
    required double distanceM,
    required double currentSpeedMs,
    double maxSpeedMs = 22.2, // ~80 km/h speed limit
    double maxAccelerationMs2 = 2.0,
  }) {
    if (distanceM <= 0) return 0.0;

    final speedDiff = maxSpeedMs - currentSpeedMs;
    final accelTime = speedDiff > 0 ? speedDiff / maxAccelerationMs2 : 0.0;
    final accelDist = (currentSpeedMs * accelTime) + (0.5 * maxAccelerationMs2 * math.pow(accelTime, 2));

    if (distanceM <= accelDist) {
      final discriminant = math.pow(currentSpeedMs, 2) + (2.0 * maxAccelerationMs2 * distanceM);
      return (-currentSpeedMs + math.sqrt(discriminant)) / maxAccelerationMs2;
    } else {
      final cruiseDist = distanceM - accelDist;
      final cruiseTime = cruiseDist / maxSpeedMs;
      return accelTime + cruiseTime;
    }
  }

  /// 6. Primary Decision Invariant: Evaluates Chance-Constrained Preemption Trigger
  /// Trigger Green iff ETA_k <= T_clear(N_crit) + T_transition
  static CCHLPDecision evaluateIntersection(CCHLPState state) {
    final etaSec = computeKinematicETA(
      distanceM: state.distanceToJunctionM,
      currentSpeedMs: state.ambulanceSpeedMs,
      maxAccelerationMs2: state.ambulanceAcceleration,
    );

    final pYield = computeConditionalYieldProbability(
      appPenetrationRate: state.appPenetrationRate,
      distanceToAmbulanceM: state.distanceToJunctionM,
      adjacentLaneFlowVehS: state.adjacentLaneFlowVehS,
    );

    final nCrit = computeCriticalResidualQueue(
      observedQueueCount: state.observedQueueCount,
      yieldProbability: pYield,
    );

    final clearanceTimeSec = computeWebsterClearanceTime(
      queueCount: nCrit,
      saturationFlowRate: state.saturationFlowRate,
      startupLostTimeSec: state.startupLostTimeSec,
    );

    final transitionTimeSec = computeTransitionSafetyDuration(
      conflictingPhaseElapsedSec: state.conflictingPhaseElapsed,
      conflictingPhaseMinGreenSec: state.conflictingPhaseMinGreen,
    );

    final totalRequiredClearanceSec = clearanceTimeSec + transitionTimeSec;
    final bool shouldTrigger = etaSec <= totalRequiredClearanceSec;

    String rationale;
    if (shouldTrigger) {
      rationale = "CHANCE-CONSTRAINED INVARIANT MET: ETA (${etaSec.toStringAsFixed(1)}s) <= "
          "Required Horizon (${totalRequiredClearanceSec.toStringAsFixed(1)}s = "
          "${clearanceTimeSec.toStringAsFixed(1)}s queue clearance + ${transitionTimeSec.toStringAsFixed(1)}s transition). "
          "Triggering Green Preemption to guarantee 99% stop-free EV transit.";
    } else {
      rationale = "HOLDING CONFLICTING PHASE: ETA (${etaSec.toStringAsFixed(1)}s) > "
          "Required Horizon (${totalRequiredClearanceSec.toStringAsFixed(1)}s). "
          "Estimated P(yield)=${(pYield * 100).toStringAsFixed(1)}% compresses critical queue to "
          "${nCrit.toStringAsFixed(1)}/${state.observedQueueCount} vehs. Preserving cross-street throughput.";
    }

    return CCHLPDecision(
      shouldTriggerPreemption: shouldTrigger,
      estimatedTimeOfArrivalSec: etaSec,
      clearanceTimeSec: clearanceTimeSec,
      transitionTimeSec: transitionTimeSec,
      yieldProbability: pYield,
      criticalResidualQueue: nCrit,
      statusRationale: rationale,
    );
  }
}
