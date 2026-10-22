import 'dart:math' as math;

/// ============================================================================
/// CC-HLP: Chance-Constrained Human-in-the-Loop Preemption Algorithm
/// 
/// Publication Model for IEEE Transactions on Intelligent Transportation Systems / ITSC:
/// 1. Webster / Newell Queue Clearance with Explicit N=0 Boundary Condition.
/// 2. Time-Aware Yielding Probability with Maneuver Deadline Feasibility.
/// 3. Heterogeneous Poisson-Binomial Residual Queue Distribution with Exact Quantile.
/// 4. Boundary-Crossing Preemption Trigger Invariant.
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
  final double averageYieldProbability;
  final int criticalResidualQueue;
  final String statusRationale;

  const CCHLPDecision({
    required this.shouldTriggerPreemption,
    required this.estimatedTimeOfArrivalSec,
    required this.clearanceTimeSec,
    required this.transitionTimeSec,
    required this.averageYieldProbability,
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
  static const double kAverageVehicleLengthM = 7.5; // l_veh
  static const double kManeuverMedianSec = 5.5; // Median maneuver execution time

  /// 1. Macroscopic Webster/Newell Queue Clearance Time with Boundary Condition
  /// T_clear(0) = 0, T_clear(N) = t_L + (N / q_max) for N >= 1
  static double computeWebsterClearanceTime({
    required int queueCount,
    double saturationFlowRate = 0.5,
    double startupLostTimeSec = 2.0,
  }) {
    if (queueCount <= 0) return 0.0;
    return startupLostTimeSec + (queueCount / saturationFlowRate);
  }

  /// 2. Time-Aware Yielding Probability for Vehicle i
  /// p_i = P(yield_behavior) * P(T_maneuver <= \Delta t_deadline(i))
  static double computeTimeAwareYieldProbability({
    required int vehicleIndex, // i \in {1, ..., N}
    required int totalQueue,
    required double distanceToAmbulanceM,
    required double ambulanceSpeedMs,
    required double appPenetrationRate,
    required double adjacentLaneFlowVehS,
  }) {
    final rhoApp = appPenetrationRate.clamp(0.0, 1.0);
    final pNet = kNetworkDeliverySuccessRate;

    // Individualized longitudinal distance separating ambulance from vehicle i:
    final distToVehicleI = distanceToAmbulanceM - ((totalQueue - vehicleIndex) * kAverageVehicleLengthM);
    const safeBufferM = 15.0; // d_safe

    // If ambulance is already past vehicle i or within safe buffer, window has expired:
    if (distToVehicleI <= safeBufferM) {
      return 0.0;
    }

    // Individualized Attention / Auditory Perception Decay Kernel:
    final pAttention = 1.0 - math.exp(-kAcousticThresholdDistanceM / (distToVehicleI + 1.0));

    // Willingness to comply:
    final pCompliance = kDriverComplianceWillingness;

    // Poisson Gap Feasibility: P(gap >= t_c) = exp(- q_adj * t_c)
    final pGap = math.exp(-adjacentLaneFlowVehS * kCriticalLaneChangeGapSec);

    final pBehavioral = rhoApp * pNet * pAttention * pCompliance * pGap;

    // Deadline feasibility: Time remaining before EV reaches vehicle i's safe buffer
    final speed = math.max(ambulanceSpeedMs, 5.0); // minimum 5 m/s
    final deadlineSec = (distToVehicleI - safeBufferM) / speed;

    // Feasibility modeled via log-normal CDF approximation (\mu_m = 1.705, \sigma_m = 0.35, median = 5.5s)
    final pFeasible = deadlineSec >= kManeuverMedianSec
        ? 1.0 - (0.5 * math.exp(-0.7 * (deadlineSec - kManeuverMedianSec)))
        : (0.5 * math.exp(0.7 * (deadlineSec - kManeuverMedianSec)));

    return (pBehavioral * pFeasible).clamp(0.0, 1.0);
  }

  /// 3. Exact Discrete Poisson-Binomial Quantile Evaluation via Recursive Convolution
  /// N_crit = min { n | F_PB(n) >= 1 - \epsilon }
  static int computeExactPoissonBinomialQuantile({
    required List<double> yieldingProbabilities,
    double riskToleranceEpsilon = 0.01, // 99% model confidence
  }) {
    final n = yieldingProbabilities.length;
    if (n == 0) return 0;

    // Remaining probabilities: q_i = 1 - p_i
    final q = yieldingProbabilities.map((p) => 1.0 - p).toList();

    // PMF of Poisson-Binomial distribution: pmf[k] is P(N_rem = k)
    // Initialized for 0 trials: P(N_rem = 0) = 1.0
    List<double> pmf = [1.0];

    for (int i = 0; i < n; i++) {
      final qi = q[i];
      final pi = 1.0 - qi; // p_i
      final nextPmf = List<double>.filled(pmf.length + 1, 0.0);

      // Convolution step: P_i(k) = P_{i-1}(k) * (1 - q_i) + P_{i-1}(k-1) * q_i
      for (int k = 0; k < pmf.length; k++) {
        nextPmf[k] += pmf[k] * pi;     // vehicle yields, does not add to remaining queue
        nextPmf[k + 1] += pmf[k] * qi; // vehicle stays, adds 1 to remaining queue
      }
      pmf = nextPmf;
    }

    // Cumulative Distribution Function (CDF):
    double cdf = 0.0;
    final targetConfidence = 1.0 - riskToleranceEpsilon;

    for (int k = 0; k < pmf.length; k++) {
      cdf += pmf[k];
      if (cdf >= targetConfidence) {
        return k;
      }
    }

    return n;
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

    // Compute heterogeneous vehicle-specific probabilities:
    final pList = <double>[];
    for (int i = 1; i <= state.observedQueueCount; i++) {
      final pi = computeTimeAwareYieldProbability(
        vehicleIndex: i,
        totalQueue: state.observedQueueCount,
        distanceToAmbulanceM: state.distanceToJunctionM,
        ambulanceSpeedMs: state.ambulanceSpeedMs,
        appPenetrationRate: state.appPenetrationRate,
        adjacentLaneFlowVehS: state.adjacentLaneFlowVehS,
      );
      pList.add(pi);
    }

    final avgP = pList.isEmpty ? 0.0 : pList.reduce((a, b) => a + b) / pList.length;

    // Exact Poisson-Binomial Quantile:
    final nCrit = computeExactPoissonBinomialQuantile(
      yieldingProbabilities: pList,
      riskToleranceEpsilon: 0.01,
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
      rationale = "BOUNDARY-CROSSING TRIGGER REACHED: ETA (${etaSec.toStringAsFixed(1)}s) <= "
          "Required Horizon (${totalRequiredClearanceSec.toStringAsFixed(1)}s = "
          "${clearanceTimeSec.toStringAsFixed(1)}s queue clearance + ${transitionTimeSec.toStringAsFixed(1)}s transition). "
          "Actuating Preemption Sequence to guarantee 99% model-based stop-free EV transit.";
    } else {
      rationale = "HOLDING CONFLICTING PHASE: ETA (${etaSec.toStringAsFixed(1)}s) > "
          "Required Horizon (${totalRequiredClearanceSec.toStringAsFixed(1)}s). "
          "Poisson-Binomial N_crit = $nCrit/${state.observedQueueCount} vehs (avg P_yield = ${(avgP * 100).toStringAsFixed(1)}%). "
          "Preserving cross-street throughput during decision horizon.";
    }

    return CCHLPDecision(
      shouldTriggerPreemption: shouldTrigger,
      estimatedTimeOfArrivalSec: etaSec,
      clearanceTimeSec: clearanceTimeSec,
      transitionTimeSec: transitionTimeSec,
      averageYieldProbability: avgP,
      criticalResidualQueue: nCrit,
      statusRationale: rationale,
    );
  }
}
