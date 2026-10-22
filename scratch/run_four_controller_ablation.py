import numpy as np
import math
import csv
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import scipy.stats as stats

# ==============================================================================
# AUDITED CC-HLP BENCHMARK SIMULATION (SEEDS 1001-1050)
# Rigorously addresses all reviewer findings:
# 1. Pinned Seeds 1001-1050 (N_SEEDS = 50)
# 2. Correct Kinematic Integration (continuous position & velocity updates)
# 3. Front-to-Back Queue Clearance Ordering (Stopline to Tail)
# 4. Strictly Passive Comparators (Obrusnik & Fixed-Distance have Pyield = 0)
# 5. Continuous Logistic Acoustic Detection Model
# 6. Automated Statistical Testing (Paired t-test and Wilcoxon signed-rank)
# ==============================================================================

# Simulation & Corridor Constants
SEEDS = list(range(1001, 1051))
N_SEEDS = len(SEEDS)
CORRIDOR_LENGTH_M = 3200.0
NUM_INTERSECTIONS = 5
BLOCK_DISTANCE_M = CORRIDOR_LENGTH_M / NUM_INTERSECTIONS  # 640.0 m

V_EV_CRUISE_MEAN = 20.0       # 72 km/h
A_EV_MAX_MS2 = 2.2            # Max acceleration
B_EV_SERVICE_MS2 = 2.5        # Normal service braking
B_EV_EMERGENCY_MS2 = 4.5      # Maximum emergency braking

VEHICLE_LENGTH_M = 7.5        # 5m vehicle + 2.5m gap
HEADWAY_S = 2.0               # Saturation headway (1800 veh/h)
T_LOST_SEC = 2.0              # Startup lost time
Q_SAT_VEH_S = 0.50            # Saturation flow rate
LAMBDA_CROSS_VEH_S = 0.16     # Cross-street arrival rate (576 veh/h)
C_CYCLE = 90.0                # Cycle length
G_CROSS_NOMINAL = 35.0        # Nominal cross-street green
T_YELLOW_SEC = 3.5            # Yellow clearance
T_ALL_RED_SEC = 2.0           # All-red clearance
G_MIN_SEC = 6.0               # Minimum cross green

MU_MANEUVER = 1.705           # Lognormal median = 5.5 s
SIGMA_MANEUVER = 0.35

def calc_transient_cross_delay(g_eff, g_norm=35.0, C=90.0, lam=0.16, s=0.50):
    """
    3-cycle Webster transient queue area integration for cross-street delay.
    """
    # Cycle 1: Preemption cycle with truncated green g_eff
    R1 = C - g_eff
    arr_red_1 = lam * R1
    area_red_1 = 0.5 * lam * (R1 ** 2)
    t_clear_1 = arr_red_1 / (s - lam)
    if t_clear_1 <= g_eff:
        area_green_1 = 0.5 * arr_red_1 * t_clear_1
        rem_q1 = 0.0
    else:
        area_green_1 = 0.5 * (arr_red_1 + (arr_red_1 - (s - lam) * g_eff)) * g_eff
        rem_q1 = arr_red_1 - (s - lam) * g_eff
    delay_c1 = area_red_1 + area_green_1

    # Cycle 2: First recovery cycle with nominal green g_norm
    R2 = C - g_norm
    arr_red_2 = lam * R2
    init_q2 = rem_q1
    peak_q2 = init_q2 + arr_red_2
    area_red_2 = 0.5 * (init_q2 + peak_q2) * R2
    t_clear_2 = peak_q2 / (s - lam)
    if t_clear_2 <= g_norm:
        area_green_2 = 0.5 * peak_q2 * t_clear_2
        rem_q2 = 0.0
    else:
        area_green_2 = 0.5 * (peak_q2 + (peak_q2 - (s - lam) * g_norm)) * g_norm
        rem_q2 = peak_q2 - (s - lam) * g_norm
    delay_c2 = area_red_2 + area_green_2

    # Cycle 3: Second recovery cycle
    R3 = C - g_norm
    arr_red_3 = lam * R3
    init_q3 = rem_q2
    peak_q3 = init_q3 + arr_red_3
    area_red_3 = 0.5 * (init_q3 + peak_q3) * R3
    t_clear_3 = peak_q3 / (s - lam)
    if t_clear_3 <= g_norm:
        area_green_3 = 0.5 * peak_q3 * t_clear_3
        rem_q3 = 0.0
    else:
        area_green_3 = 0.5 * (peak_q3 + (peak_q3 - (s - lam) * g_norm)) * g_norm
        rem_q3 = peak_q3 - (s - lam) * g_norm
    delay_c3 = area_red_3 + area_green_3

    return (delay_c1 + delay_c2 + delay_c3) / (3.0 * lam * C)

def run_audited_benchmark(rho_app=0.60, epsilon=0.05):
    controllers = [
        "1. Fixed-Distance (300m Static)",
        "2. Queue-Discharge (Obrusnik 2020)",
        "3. Reactive Observer (2s Sensor Polling)",
        "4. CC-HLP (Proposed Predictive)"
    ]

    per_seed_records = []

    metrics = {c: {
        "travel_time": [],
        "braking_episodes": [],
        "complete_stops": [],
        "clearance_violations": [],
        "cross_delay": [],
        "preempt_duration": []
    } for c in controllers}

    for seed in SEEDS:
        rng = np.random.default_rng(seed)

        # Common Random Numbers (CRN) across all 4 controllers:
        initial_queues = [int(rng.poisson(8.0)) for _ in range(NUM_INTERSECTIONS)]
        phase_elapsed = [float(rng.uniform(0.0, 20.0)) for _ in range(NUM_INTERSECTIONS)]
        v_desired = float(np.clip(rng.normal(V_EV_CRUISE_MEAN, 0.85), 17.5, 22.2))

        # Generate queued vehicles for each intersection:
        # ORDER: Front-to-Back (k=1 is at stopline, k=N_init is at tail)
        corridor_traffic = []
        for j in range(NUM_INTERSECTIONS):
            junction_pos = (j + 1) * BLOCK_DISTANCE_M
            N_init = initial_queues[j]
            j_vehs = []
            for k in range(1, N_init + 1):
                # k=1: stopline (junction_pos - 7.5m), k=N: tail (junction_pos - N*7.5m)
                pos = junction_pos - k * VEHICLE_LENGTH_M
                has_app = bool(rng.binomial(1, rho_app * 0.96))
                has_gap = bool(rng.binomial(1, 0.82))
                is_compliant = bool(rng.binomial(1, 0.92))
                maneuver_dur = float(rng.lognormal(MU_MANEUVER, SIGMA_MANEUVER))
                
                # Sample acoustic perception threshold from continuous logistic model:
                # P(acoustic | dx) = 1 / (1 + exp((dx - 180)/30))
                # Inverse transform: dx_thresh = 180 - 30 * ln(1/u - 1)
                u = float(rng.uniform(0.02, 0.98))
                acoustic_perceive_dist = float(np.clip(180.0 - 30.0 * math.log((1.0 / u) - 1.0), 60.0, 300.0))

                j_vehs.append({
                    "rank": k,
                    "pos": pos,
                    "has_app": has_app,
                    "has_gap": has_gap,
                    "is_compliant": is_compliant,
                    "dur": maneuver_dur,
                    "acoustic_dist": acoustic_perceive_dist
                })
            corridor_traffic.append(j_vehs)

        # Simulate each controller under the EXACT SAME traffic realization:
        for c_idx, c_name in enumerate(controllers):
            clock = 0.0
            ev_pos = 0.0
            ev_speed = v_desired

            tot_braking_episodes = 0
            tot_complete_stops = 0
            tot_clearance_violations = 0
            tot_preempt_duration = 0.0
            tot_cross_delay = 0.0

            for j in range(NUM_INTERSECTIONS):
                junction_pos = (j + 1) * BLOCK_DISTANCE_M
                N_init = initial_queues[j]
                g_el = phase_elapsed[j]
                t_transition = max(0.0, G_MIN_SEC - g_el) + T_YELLOW_SEC + T_ALL_RED_SEC
                vehs_data = corridor_traffic[j]

                # Determine driver yielding behavior based on controller type:
                # For Baselines 1 & 2: Traffic is PASSIVE (no voluntary yields, Pyield = 0)
                # For Baselines 3 & 4: Participatory mobile alerts enable voluntary yielding
                veh_states = []
                for v in vehs_data:
                    if c_idx in [0, 1]:
                        # PASSIVE TRAFFIC COMPARATOR: Drivers disperse only after signal turns green
                        will_yield = False
                        t_alert = float('inf')
                        t_vacate = float('inf')
                    else:
                        # PARTICIPATORY TRAFFIC: Drivers receive mobile or siren alerts
                        if v["has_app"]:
                            t_alert = clock  # Instantaneous 5G/LTE push notification
                        else:
                            d_to_veh = v["pos"] - ev_pos
                            t_siren_reach = clock + max(0.0, (d_to_veh - v["acoustic_dist"]) / max(ev_speed, 5.0))
                            t_alert = t_siren_reach

                        ev_pos_at_alert = min(v["pos"] - 15.0, ev_pos + (t_alert - clock) * ev_speed)
                        avail_dist = v["pos"] - ev_pos_at_alert - 15.0
                        avail_time = avail_dist / max(ev_speed, 5.0)

                        will_yield = v["has_gap"] and v["is_compliant"] and (v["dur"] <= avail_time) and (avail_time > 0.0)
                        t_vacate = (t_alert + v["dur"]) if will_yield else float('inf')

                    veh_states.append({
                        "rank": v["rank"],
                        "pos": v["pos"],
                        "will_yield": will_yield,
                        "t_alert": t_alert,
                        "t_vacate": t_vacate
                    })

                eta_j = (junction_pos - ev_pos) / max(ev_speed, 5.0)

                # Preemption Trigger Logic:
                if c_idx == 0:
                    # 1. Fixed-Distance EVP (300m Static Trigger)
                    t_lead = min(eta_j, 300.0 / max(ev_speed, 5.0))
                    preempt_start = clock + (eta_j - t_lead)

                elif c_idx == 1:
                    # 2. Pure Queue-Discharge Baseline (Obrusnik et al., 2020)
                    t_clear_plan = T_LOST_SEC + N_init * HEADWAY_S if N_init > 0 else 0.0
                    t_lead = min(eta_j, t_clear_plan + t_transition)
                    preempt_start = clock + (eta_j - t_lead)

                elif c_idx == 2:
                    # 3. Strictly Causal Sensor-Driven Reactive Observer (2s Sensor Polling)
                    triggered = False
                    preempt_start = clock + eta_j
                    t_poll = clock
                    while t_poll <= clock + eta_j:
                        eta_poll = max(0.0, (junction_pos - (ev_pos + (t_poll - clock) * ev_speed)) / max(ev_speed, 5.0))
                        # Sensor can only observe vehicles that have ALREADY vacated at t_poll:
                        n_detected = sum(1 for vs in veh_states if t_poll < vs["t_vacate"])
                        t_clear_obs = T_LOST_SEC + n_detected * HEADWAY_S if n_detected > 0 else 0.0
                        lead_needed = t_clear_obs + t_transition

                        if eta_poll <= lead_needed:
                            preempt_start = t_poll
                            triggered = True
                            break
                        t_poll += 2.0

                    if not triggered:
                        preempt_start = clock + eta_j

                elif c_idx == 3:
                    # 4. Proposed CC-HLP (Chance-Constrained Human-in-the-Loop)
                    p_yield_list = []
                    for vs in veh_states:
                        dx = max(10.0, vs["pos"] - ev_pos)
                        p_acoustic = 1.0 / (1.0 + math.exp((dx - 180.0) / 30.0))
                        p_mobile = rho_app * 0.96
                        p_alert = 1.0 - (1.0 - p_mobile) * (1.0 - p_acoustic)
                        p_gap = 0.82
                        c_base = 0.92
                        avail_d = max(0.0, vs["pos"] - ev_pos - 15.0)
                        if avail_d <= 0.0:
                            p_feas = 0.0
                        else:
                            dt_dead = avail_d / max(ev_speed, 5.0)
                            z = (math.log(dt_dead) - MU_MANEUVER) / SIGMA_MANEUVER
                            p_feas = 0.5 * (1.0 + math.erf(z / math.sqrt(2.0)))
                        p_i = p_alert * c_base * p_gap * p_feas
                        p_yield_list.append(float(np.clip(p_i, 0.0, 0.98)))

                    # Discrete Poisson-Binomial Convolution:
                    pmf = [1.0]
                    for p in p_yield_list:
                        q_val = 1.0 - p
                        next_pmf = [0.0] * (len(pmf) + 1)
                        for k in range(len(pmf)):
                            next_pmf[k] += pmf[k] * p
                            next_pmf[k+1] += pmf[k] * q_val
                        pmf = next_pmf

                    cdf = 0.0
                    n_crit = len(p_yield_list)
                    for k_idx, prob in enumerate(pmf):
                        cdf += prob
                        if cdf >= (1.0 - epsilon):
                            n_crit = k_idx
                            break

                    t_clear_pred = T_LOST_SEC + n_crit * HEADWAY_S if n_crit > 0 else 0.0
                    t_lead = min(eta_j, t_clear_pred + t_transition)
                    preempt_start = clock + (eta_j - t_lead)

                # Signal Execution
                green_display = preempt_start + t_transition

                # Physical Stopline Queue Discharge (Front-to-Back: rank 1 to N_init)
                t_lane_clear = green_display
                discharged_count = 0
                for vs in veh_states:
                    if vs["will_yield"]:
                        # If vehicle yields into adjacent lane, it vacates at t_vacate
                        t_discharge_if_stayed = green_display + T_LOST_SEC + (discharged_count + 1) * HEADWAY_S
                        if vs["t_vacate"] < t_discharge_if_stayed:
                            # Vacated early voluntarily
                            t_clear_this = vs["t_vacate"]
                        else:
                            # Remained in lane until signal discharge
                            discharged_count += 1
                            t_clear_this = t_discharge_if_stayed
                    else:
                        # Non-yielding: discharges through green phase
                        discharged_count += 1
                        t_clear_this = green_display + T_LOST_SEC + discharged_count * HEADWAY_S

                    t_lane_clear = max(t_lane_clear, t_clear_this)

                # Clearance Headroom Violation Check:
                ev_arrival_expected = clock + eta_j
                if ev_arrival_expected < t_lane_clear:
                    tot_clearance_violations += 1

                # Continuous Microscopic Kinematic Integration (dt = 0.1 s):
                dt = 0.1
                t_sim = clock
                x_sim = ev_pos
                v_sim = ev_speed
                in_braking_episode = False
                braking_episodes_at_junction = 0
                stopped_at_junction = False

                while x_sim < junction_pos:
                    dist_to_stopline = junction_pos - x_sim
                    is_stopline_blocked = (t_sim < green_display) or (t_sim < t_lane_clear)

                    if is_stopline_blocked and dist_to_stopline < 85.0:
                        # Decelerate to avoid collision with blocked stopline
                        required_decel = (v_sim ** 2) / (2.0 * max(1.0, dist_to_stopline))
                        a_sim = -min(B_EV_EMERGENCY_MS2, max(B_EV_SERVICE_MS2, required_decel))

                        if a_sim <= -2.0:
                            if not in_braking_episode:
                                in_braking_episode = True
                                braking_episodes_at_junction += 1
                        else:
                            in_braking_episode = False

                        v_sim = max(0.0, v_sim + a_sim * dt)
                        if v_sim < 0.05:
                            v_sim = 0.0
                            stopped_at_junction = True
                    else:
                        in_braking_episode = False
                        if v_sim < v_desired:
                            a_sim = min(A_EV_MAX_MS2, (v_desired - v_sim) / dt)
                            v_sim = min(v_desired, v_sim + a_sim * dt)
                        else:
                            a_sim = 0.0

                    # Monotonic position and time progression:
                    x_sim += v_sim * dt
                    t_sim += dt

                tot_braking_episodes += braking_episodes_at_junction
                if stopped_at_junction:
                    tot_complete_stops += 1

                # Preemption duration & cross-street delay calculation:
                preempt_end = t_sim + 2.0
                junc_preempt = max(0.0, preempt_end - preempt_start)
                tot_preempt_duration += junc_preempt

                stolen_g = max(0.0, junc_preempt - t_transition)
                g_eff = max(G_MIN_SEC, G_CROSS_NOMINAL - stolen_g)
                tot_cross_delay += calc_transient_cross_delay(g_eff)

                # Advance to next link:
                clock = t_sim
                ev_pos = junction_pos
                ev_speed = v_desired

            avg_cross_delay = tot_cross_delay / NUM_INTERSECTIONS
            metrics[c_name]["travel_time"].append(clock)
            metrics[c_name]["braking_episodes"].append(tot_braking_episodes)
            metrics[c_name]["complete_stops"].append(tot_complete_stops)
            metrics[c_name]["clearance_violations"].append(tot_clearance_violations)
            metrics[c_name]["cross_delay"].append(avg_cross_delay)
            metrics[c_name]["preempt_duration"].append(tot_preempt_duration)

            per_seed_records.append({
                "seed": seed,
                "controller": c_name,
                "ev_travel_time": round(clock, 2),
                "braking_episodes": tot_braking_episodes,
                "complete_stops": tot_complete_stops,
                "clearance_violations": tot_clearance_violations,
                "cross_street_delay": round(avg_cross_delay, 2),
                "preempt_duration": round(tot_preempt_duration, 2)
            })

    # Save audited per-seed CSV
    csv_path = "scratch/per_seed_benchmark_results.csv"
    with open(csv_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=[
            "seed", "controller", "ev_travel_time", "braking_episodes",
            "complete_stops", "clearance_violations", "cross_street_delay", "preempt_duration"
        ])
        writer.writeheader()
        writer.writerows(per_seed_records)

    return metrics, controllers

metrics, controllers = run_audited_benchmark(rho_app=0.60, epsilon=0.05)

# ==============================================================================
# AUDITED STATISTICAL SUMMARY & AUTOMATED PAIRED TESTS
# ==============================================================================
print("\n" + "=" * 120)
print(f"AUDITED CC-HLP BENCHMARK RESULTS (SEEDS 1001-1050, N={N_SEEDS}, DDOF=1)")
print("=" * 120)

for c in controllers:
    tt_m, tt_s = np.mean(metrics[c]["travel_time"]), np.std(metrics[c]["travel_time"], ddof=1)
    br_m, br_s = np.mean(metrics[c]["braking_episodes"]), np.std(metrics[c]["braking_episodes"], ddof=1)
    st_m, st_s = np.mean(metrics[c]["complete_stops"]), np.std(metrics[c]["complete_stops"], ddof=1)
    pr_m, pr_s = np.mean(metrics[c]["preempt_duration"]), np.std(metrics[c]["preempt_duration"], ddof=1)
    cd_m, cd_s = np.mean(metrics[c]["cross_delay"]), np.std(metrics[c]["cross_delay"], ddof=1)

    print(f"[{c}]")
    print(f"  EV Travel Time:     {tt_m:.2f} ± {tt_s:.2f} s")
    print(f"  Decel Episodes:     {br_m:.2f} ± {br_s:.2f}")
    print(f"  Complete Stops:     {st_m:.2f} ± {st_s:.2f}")
    print(f"  Preempt Duration:   {pr_m:.2f} ± {pr_s:.2f} s (per junc: {pr_m/5:.2f} s)")
    print(f"  Cross-Street Delay: {cd_m:.2f} ± {cd_s:.2f} s/veh")

# Compute Paired Tests between CC-HLP and Obrusnik Baseline:
c_cchlp = controllers[3]
c_obrusnik = controllers[1]
c_observer = controllers[2]
c_fixed = controllers[0]

print("\n" + "=" * 120)
print("PAIRED STATISTICAL HYPOTHESIS TESTS (CC-HLP vs COMPARATORS)")
print("=" * 120)

for comp_name, comp_key in [("Obrusnik Baseline", c_obrusnik), ("Reactive Observer", c_observer), ("Fixed Distance", c_fixed)]:
    print(f"\n--- CC-HLP vs. {comp_name} ---")
    for metric_name in ["travel_time", "braking_episodes", "preempt_duration", "cross_delay"]:
        x = np.array(metrics[c_cchlp][metric_name])
        y = np.array(metrics[comp_key][metric_name])
        diff = x - y
        diff_mean = np.mean(diff)
        diff_std = np.std(diff, ddof=1)

        t_res = stats.ttest_rel(x, y)
        w_res = stats.wilcoxon(x, y) if not np.all(diff == 0) else None

        w_p = w_res.pvalue if w_res else 1.0
        print(f"  {metric_name:<18}: Mean Diff = {diff_mean:+.2f} ± {diff_std:.2f} | t-stat = {t_res.statistic:+.3f} (p={t_res.pvalue:.4e}) | Wilcoxon p = {w_p:.4e}")

# ==============================================================================
# GENERATE UPDATED PUBLICATION-GRADE FIGURE 1
# ==============================================================================
fig, axes = plt.subplots(2, 2, figsize=(14, 10))
labels = ["Fixed-Dist\n(300m)", "Queue-Aware\n(Obrusník)", "Reactive\nObserver", "Proposed\nCC-HLP"]
colors = ['#e74c3c', '#e67e22', '#3498db', '#2ecc71']

# 1. Travel Time
tm = [np.mean(metrics[c]["travel_time"]) for c in controllers]
ts = [np.std(metrics[c]["travel_time"], ddof=1) for c in controllers]
axes[0, 0].bar(labels, tm, yerr=ts, capsize=6, color=colors, alpha=0.88, edgecolor='black')
axes[0, 0].set_title("Corridor EV Travel Time (3.2 km, 5 Junctions)", fontsize=12, fontweight='bold')
axes[0, 0].set_ylabel("Travel Time (s)", fontsize=11)
axes[0, 0].grid(axis='y', linestyle='--', alpha=0.6)

# 2. Braking Episodes
bm = [np.mean(metrics[c]["braking_episodes"]) for c in controllers]
bs = [np.std(metrics[c]["braking_episodes"], ddof=1) for c in controllers]
axes[0, 1].bar(labels, bm, yerr=bs, capsize=6, color='#f39c12', alpha=0.88, edgecolor='black')
axes[0, 1].set_title("EV Deceleration Episodes (a <= -2.0 m/s²)", fontsize=12, fontweight='bold')
axes[0, 1].set_ylabel("Average Episodes per Run", fontsize=11)
axes[0, 1].grid(axis='y', linestyle='--', alpha=0.6)

# 3. Cross Delay
dm = [np.mean(metrics[c]["cross_delay"]) for c in controllers]
ds = [np.std(metrics[c]["cross_delay"], ddof=1) for c in controllers]
axes[1, 0].bar(labels, dm, yerr=ds, capsize=6, color=colors, alpha=0.88, edgecolor='black')
axes[1, 0].set_title("Cross-Street Average Vehicle Delay (Webster Integration)", fontsize=12, fontweight='bold')
axes[1, 0].set_ylabel("Delay (s / vehicle)", fontsize=11)
axes[1, 0].grid(axis='y', linestyle='--', alpha=0.6)

# 4. Preempt Duration
pm = [np.mean(metrics[c]["preempt_duration"]) for c in controllers]
ps = [np.std(metrics[c]["preempt_duration"], ddof=1) for c in controllers]
axes[1, 1].bar(labels, pm, yerr=ps, capsize=6, color=colors, alpha=0.88, edgecolor='black')
axes[1, 1].set_title("Total Corridor Preemption Green Held", fontsize=12, fontweight='bold')
axes[1, 1].set_ylabel("Corridor Preemption Duration (s)", fontsize=11)
axes[1, 1].grid(axis='y', linestyle='--', alpha=0.6)

plt.tight_layout()
plt.savefig("four_controller_ablation_results.png", dpi=300)
print("\n[SUCCESS] Saved updated publication plot: four_controller_ablation_results.png")
print("[SUCCESS] Saved audited per-seed CSV: scratch/per_seed_benchmark_results.csv")
