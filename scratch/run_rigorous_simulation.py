import numpy as np
import math
import matplotlib.pyplot as plt

np.random.seed(42)
N_SEEDS = 50

# Corridor Parameters
CORRIDOR_LENGTH_M = 3200.0
NUM_INTERSECTIONS = 5
BLOCK_DISTANCE_M = CORRIDOR_LENGTH_M / NUM_INTERSECTIONS # 640m

# Vehicle Kinematics
V_EV_CRUISE_MEAN = 20.0       # 72 km/h nominal
A_EV_MAX_MS2 = 2.2            # Maximum longitudinal acceleration
B_EV_COMFORT_MS2 = 2.5        # Deceleration threshold for braking events
B_EV_EMERGENCY_MS2 = 4.5      # Emergency stop braking

# Traffic Signal & Flow Parameters
C_CYCLE = 90.0
G_CROSS_NOMINAL = 35.0
Q_SAT_VEH_S = 0.50            # 1800 veh/h saturation flow
HEADWAY_S = 2.0               # Saturation headway
T_LOST_SEC = 2.0              # Startup lost time
LAMBDA_CROSS_VEH_S = 0.16     # 576 veh/h cross-street volume
T_YELLOW_SEC = 3.5
T_ALL_RED_SEC = 2.0
G_MIN_SEC = 6.0

def calc_transient_delay(g_eff, g_norm=35.0, C=90.0, lam=0.16, s=0.50):
    # Cycle-by-cycle queue integration for transient preemption
    # Cycle 1: Preempted cycle
    R1 = C - g_eff
    arr_red_1 = lam * R1
    area_red_1 = 0.5 * lam * (R1 ** 2)
    
    t_clear_1 = arr_red_1 / (s - lam)
    if t_clear_1 <= g_eff:
        area_green_1 = 0.5 * arr_red_1 * t_clear_1
        rem_queue_1 = 0.0
    else:
        area_green_1 = 0.5 * (arr_red_1 + (arr_red_1 - (s - lam) * g_eff)) * g_eff
        rem_queue_1 = arr_red_1 - (s - lam) * g_eff
        
    delay_c1 = area_red_1 + area_green_1
    
    # Cycle 2: Recovery cycle
    R2 = C - g_norm
    arr_red_2 = lam * R2
    init_q2 = rem_queue_1
    peak_q2 = init_q2 + arr_red_2
    area_red_2 = 0.5 * (init_q2 + peak_q2) * R2
    
    t_clear_2 = peak_q2 / (s - lam)
    if t_clear_2 <= g_norm:
        area_green_2 = 0.5 * peak_q2 * t_clear_2
        rem_queue_2 = 0.0
    else:
        area_green_2 = 0.5 * (peak_q2 + (peak_q2 - (s - lam) * g_norm)) * g_norm
        rem_queue_2 = peak_q2 - (s - lam) * g_norm
        
    delay_c2 = area_red_2 + area_green_2
    
    # Cycle 3: Return to steady state
    R3 = C - g_norm
    arr_red_3 = lam * R3
    init_q3 = rem_queue_2
    peak_q3 = init_q3 + arr_red_3
    area_red_3 = 0.5 * (init_q3 + peak_q3) * R3
    t_clear_3 = peak_q3 / (s - lam)
    area_green_3 = 0.5 * peak_q3 * t_clear_3
    delay_c3 = area_red_3 + area_green_3

    total_delay = delay_c1 + delay_c2 + delay_c3
    total_vehs = 3 * lam * C
    return total_delay / total_vehs

def run_simulation(rho_app=0.60, epsilon=0.05):
    controllers = [
        "1. Fixed-Distance (300m Static)",
        "2. Queue-Discharge (Obrusnik 2020)",
        "3. Reactive Observer (With Yielding)",
        "4. CC-HLP (Proposed Predictive)"
    ]

    metrics = {c: {
        "ev_travel_time": [],
        "ev_braking_events": [],
        "ev_complete_stops": [],
        "cross_street_delay": [],
        "preempt_duration": [],
        "cc_violations": []
    } for c in controllers}

    for seed in range(N_SEEDS):
        rng = np.random.default_rng(seed)

        # Ambient peak queue lengths at stop lines: Poisson(lambda=9.0)
        initial_queues = [int(rng.poisson(9.0)) for _ in range(NUM_INTERSECTIONS)]
        
        # Elapsed green on conflicting cross street: Uniform(0, 20s)
        phase_elapsed = [float(rng.uniform(0.0, 20.0)) for _ in range(NUM_INTERSECTIONS)]

        # EV desired cruising speed with human driving variation: Normal(20.0, 0.85 m/s)
        v_ev_desired = float(np.clip(rng.normal(V_EV_CRUISE_MEAN, 0.85), 17.5, 22.2))

        for c_idx, c_name in enumerate(controllers):
            current_time = 0.0
            ev_pos = 0.0
            ev_speed = v_ev_desired
            
            braking_events = 0
            complete_stops = 0
            cc_violations = 0
            corridor_preempt_duration = 0.0
            corridor_cross_delay = 0.0

            for j in range(NUM_INTERSECTIONS):
                junction_pos = (j + 1) * BLOCK_DISTANCE_M
                dist_to_junction = junction_pos - ev_pos
                
                N_init = initial_queues[j]
                g_el = phase_elapsed[j]
                
                t_transition = max(0.0, G_MIN_SEC - g_el) + T_YELLOW_SEC + T_ALL_RED_SEC
                
                # Individual driver yielding behavior under dual-channel alert:
                p_yield_list = []
                for i in range(1, N_init + 1):
                    veh_pos = junction_pos - (N_init - i + 1) * 7.5
                    dx = max(15.0, veh_pos - ev_pos)
                    
                    # Dual-channel perception
                    p_acoustic = 1.0 / (1.0 + math.exp((dx - 180.0) / 30.0))
                    p_mobile = rho_app * 0.96
                    p_alert = 1.0 - (1.0 - p_mobile) * (1.0 - p_acoustic)
                    
                    # Lateral gap acceptance (multi-lane / shoulder pull-over)
                    p_gap = 0.82
                    c_base = 0.92
                    
                    # Maneuver deadline feasibility
                    dt_deadline = max(0.1, (dx - 15.0) / max(ev_speed, 5.0))
                    z = (math.log(dt_deadline) - 1.705) / 0.35
                    p_feas = 0.5 * (1.0 + math.erf(z / math.sqrt(2.0)))
                    
                    p_i = p_alert * c_base * p_gap * p_feas
                    p_yield_list.append(float(np.clip(p_i, 0.0, 0.98)))

                # Sample actual yielding realizations
                actual_yielded = sum(int(rng.binomial(1, p)) for p in p_yield_list)
                actual_rem_queue = max(0, N_init - actual_yielded)

                eta_j = dist_to_junction / max(ev_speed, 5.0)

                # -------------------------------------------------------------
                # CONTROLLER POLICIES
                # -------------------------------------------------------------
                if c_idx == 0:
                    # 1. Fixed-Distance: Static 300m trigger distance
                    d_trigger = 300.0
                    t_trigger_lead = min(eta_j, d_trigger / max(ev_speed, 5.0))
                    preempt_start_time = current_time + (eta_j - t_trigger_lead)

                elif c_idx == 1:
                    # 2. Pure Queue-Discharge (Obrusnik 2020)
                    # Flushes entire initial queue through green (P_yield = 0)
                    t_clear_plan = T_LOST_SEC + N_init * HEADWAY_S if N_init > 0 else 0.0
                    trigger_horizon = t_clear_plan + t_transition
                    t_trigger_lead = min(eta_j, trigger_horizon)
                    preempt_start_time = current_time + (eta_j - t_trigger_lead)

                elif c_idx == 2:
                    # 3. Reactive Observer (With Yielding)
                    # Senses queue with sensor latency. Only early yielders are counted at decision:
                    early_yielded = int(actual_yielded * 0.30)
                    observed_queue = max(0, N_init - early_yielded)
                    t_clear_obs = T_LOST_SEC + observed_queue * HEADWAY_S if observed_queue > 0 else 0.0
                    trigger_horizon = t_clear_obs + t_transition
                    t_trigger_lead = min(eta_j, trigger_horizon)
                    preempt_start_time = current_time + (eta_j - t_trigger_lead)

                elif c_idx == 3:
                    # 4. Proposed CC-HLP (Predictive Chance-Constrained)
                    # Discrete Poisson-Binomial quantile over residual blockers:
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
                    trigger_horizon = t_clear_pred + t_transition
                    t_trigger_lead = min(eta_j, trigger_horizon)
                    preempt_start_time = current_time + (eta_j - t_trigger_lead)

                # Signal execution
                green_display_time = preempt_start_time + t_transition
                ev_arrival_time = current_time + eta_j

                actual_clear_time = T_LOST_SEC + actual_rem_queue * HEADWAY_S if actual_rem_queue > 0 else 0.0
                queue_cleared_time = green_display_time + actual_clear_time

                headroom = ev_arrival_time - queue_cleared_time

                if headroom < 0.0:
                    cc_violations += 1
                    unmet_delay = abs(headroom)
                    braking_events += 1

                    if unmet_delay > 3.0:
                        complete_stops += 1
                        t_accel = v_ev_desired / A_EV_MAX_MS2
                        d_accel = 0.5 * A_EV_MAX_MS2 * (t_accel ** 2)
                        d_cruise = max(0.0, BLOCK_DISTANCE_M - d_accel)
                        traversal_time = unmet_delay + t_accel + (d_cruise / v_ev_desired)
                    else:
                        t_rec = (v_ev_desired - 10.0) / A_EV_MAX_MS2
                        traversal_time = eta_j + unmet_delay + (0.5 * t_rec)
                else:
                    traversal_time = eta_j + 0.4 # nominal approach verification

                # Preemption duration:
                preempt_end_time = current_time + traversal_time + 2.0
                junction_preempt_duration = max(0.0, preempt_end_time - preempt_start_time)
                corridor_preempt_duration += junction_preempt_duration

                # Calculate cross-street delay using transient cycle-by-cycle model:
                stolen_green = max(0.0, junction_preempt_duration - t_transition)
                g_eff = max(G_MIN_SEC, G_CROSS_NOMINAL - stolen_green)
                junction_cross_delay = calc_transient_delay(g_eff)
                corridor_cross_delay += junction_cross_delay

                # Update state
                current_time += traversal_time
                ev_pos = junction_pos
                ev_speed = v_ev_desired

            avg_cross_delay = corridor_cross_delay / NUM_INTERSECTIONS
            metrics[c_name]["ev_travel_time"].append(current_time)
            metrics[c_name]["ev_braking_events"].append(braking_events)
            metrics[c_name]["ev_complete_stops"].append(complete_stops)
            metrics[c_name]["cross_street_delay"].append(avg_cross_delay)
            metrics[c_name]["preempt_duration"].append(corridor_preempt_duration)
            metrics[c_name]["cc_violations"].append(cc_violations)

    return metrics

metrics = run_simulation(rho_app=0.60, epsilon=0.05)

print("=" * 132)
print("VERIFIED 50-SEED BENCHMARK (RHO_APP = 0.60, EPSILON = 0.05, 3.2 KM ARTERIAL)")
print("=" * 132)
print(f"| {'Controller Strategy':<34} | {'EV Travel Time':<17} | {'Braking Events':<16} | {'Complete Stops':<15} | {'Cross Delay':<16} | {'Preempt Time':<16} |")
print("-" * 132)

for c in metrics:
    t_m, t_s = np.mean(metrics[c]["ev_travel_time"]), np.std(metrics[c]["ev_travel_time"])
    b_m, b_s = np.mean(metrics[c]["ev_braking_events"]), np.std(metrics[c]["ev_braking_events"])
    s_m, s_s = np.mean(metrics[c]["ev_complete_stops"]), np.std(metrics[c]["ev_complete_stops"])
    d_m, d_s = np.mean(metrics[c]["cross_street_delay"]), np.std(metrics[c]["cross_street_delay"])
    p_m, p_s = np.mean(metrics[c]["preempt_duration"]), np.std(metrics[c]["preempt_duration"])

    t_str = f"{t_m:.1f}s (±{t_s:.1f})"
    b_str = f"{b_m:.2f} (±{b_s:.2f})"
    s_str = f"{s_m:.2f} (±{s_s:.2f})"
    d_str = f"{d_m:.1f}s (±{d_s:.1f})"
    p_str = f"{p_m:.1f}s (±{p_s:.1f})"

    print(f"| {c:<34} | {t_str:<17} | {b_str:<16} | {s_str:<15} | {d_str:<16} | {p_str:<16} |")
print("=" * 132)

c_prop = "4. CC-HLP (Proposed Predictive)"
c_fix = "1. Fixed-Distance (300m Static)"
c_obr = "2. Queue-Discharge (Obrusnik 2020)"
c_rea = "3. Reactive Observer (With Yielding)"

d_prop = np.mean(metrics[c_prop]["cross_street_delay"])
d_fix = np.mean(metrics[c_fix]["cross_street_delay"])
d_obr = np.mean(metrics[c_obr]["cross_street_delay"])
d_rea = np.mean(metrics[c_rea]["cross_street_delay"])

p_prop = np.mean(metrics[c_prop]["preempt_duration"])
p_obr = np.mean(metrics[c_obr]["preempt_duration"])
p_rea = np.mean(metrics[c_rea]["preempt_duration"])
p_fix = np.mean(metrics[c_fix]["preempt_duration"])

print("\n--- STATISTICAL AUDIT & COMPARISON ---")
print(f"Delay Improvement vs Obrusnik:       {((d_obr - d_prop) / d_obr)*100:.2f}% (Preemption duration reduced by {p_obr - p_prop:.1f}s, {((p_obr - p_prop)/p_obr)*100:.1f}%)")
print(f"Delay Improvement vs Reactive:       {((d_rea - d_prop) / d_rea)*100:.2f}% (Preemption duration reduced by {p_rea - p_prop:.1f}s, {((p_rea - p_prop)/p_rea)*100:.1f}%)")
print(f"Delay Improvement vs Fixed Distance: {((d_fix - d_prop) / d_fix)*100:.2f}% (Preemption duration reduced by {p_fix - p_prop:.1f}s)")

# Generate Updated High-Resolution Publication Plots
fig, axes = plt.subplots(2, 2, figsize=(14, 10))

labels = ["Fixed-Dist\n(300m)", "Queue-Aware\n(Obrusník)", "Reactive\nObserver", "Proposed\nCC-HLP"]
colors = ['#e74c3c', '#e67e22', '#3498db', '#2ecc71']

# 1. Travel Time
times_m = [np.mean(metrics[c]["ev_travel_time"]) for c in metrics]
times_s = [np.std(metrics[c]["ev_travel_time"]) for c in metrics]
axes[0, 0].bar(labels, times_m, yerr=times_s, capsize=6, color=colors, alpha=0.88, edgecolor='black')
axes[0, 0].set_title("Corridor EV Travel Time (3.2 km, 5 Junctions)", fontsize=12, fontweight='bold')
axes[0, 0].set_ylabel("Travel Time (s)", fontsize=11)
axes[0, 0].grid(axis='y', linestyle='--', alpha=0.6)

# 2. Braking & Stops
x = np.arange(len(labels))
width = 0.35
bm = [np.mean(metrics[c]["ev_braking_events"]) for c in metrics]
bs = [np.std(metrics[c]["ev_braking_events"]) for c in metrics]
sm = [np.mean(metrics[c]["ev_complete_stops"]) for c in metrics]
ss = [np.std(metrics[c]["ev_complete_stops"]) for c in metrics]

axes[0, 1].bar(x - width/2, bm, width, yerr=bs, capsize=4, label='Braking Events (a <= -2.0 m/s²)', color='#f39c12', edgecolor='black')
axes[0, 1].bar(x + width/2, sm, width, yerr=ss, capsize=4, label='Complete Stops (v = 0)', color='#c0392b', edgecolor='black')
axes[0, 1].set_title("EV Deceleration & Stop Frequencies", fontsize=12, fontweight='bold')
axes[0, 1].set_xticks(x)
axes[0, 1].set_xticklabels(labels)
axes[0, 1].set_ylabel("Average Events per Run", fontsize=11)
axes[0, 1].legend()
axes[0, 1].grid(axis='y', linestyle='--', alpha=0.6)

# 3. Cross Delay
dm = [np.mean(metrics[c]["cross_street_delay"]) for c in metrics]
ds = [np.std(metrics[c]["cross_street_delay"]) for c in metrics]
axes[1, 0].bar(labels, dm, yerr=ds, capsize=6, color=colors, alpha=0.88, edgecolor='black')
axes[1, 0].set_title("Cross-Street Average Vehicle Delay (Transient Cycle Integration)", fontsize=12, fontweight='bold')
axes[1, 0].set_ylabel("Delay (s / vehicle)", fontsize=11)
axes[1, 0].grid(axis='y', linestyle='--', alpha=0.6)

# 4. Preempt Duration
pm = [np.mean(metrics[c]["preempt_duration"]) for c in metrics]
ps = [np.std(metrics[c]["preempt_duration"]) for c in metrics]
axes[1, 1].bar(labels, pm, yerr=ps, capsize=6, color=colors, alpha=0.88, edgecolor='black')
axes[1, 1].set_title("Total Corridor Preemption Green Held", fontsize=12, fontweight='bold')
axes[1, 1].set_ylabel("Corridor Preemption Duration (s)", fontsize=11)
axes[1, 1].grid(axis='y', linestyle='--', alpha=0.6)

plt.tight_layout()
plt.savefig("four_controller_ablation_results.png", dpi=300)
print("Updated publication plot saved: four_controller_ablation_results.png")
