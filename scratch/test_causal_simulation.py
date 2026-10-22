import numpy as np
import math

np.random.seed(42)
N_SEEDS = 50

CORRIDOR_LENGTH_M = 3200.0
NUM_INTERSECTIONS = 5
BLOCK_DISTANCE_M = CORRIDOR_LENGTH_M / NUM_INTERSECTIONS # 640m

V_EV_CRUISE_MEAN = 20.0
A_EV_MAX_MS2 = 2.2
B_EV_SERVICE_MS2 = 2.5
B_EV_EMERGENCY_MS2 = 4.5
VEHICLE_LENGTH_M = 7.5

C_CYCLE = 90.0
G_CROSS_NOMINAL = 35.0
Q_SAT_VEH_S = 0.50
HEADWAY_S = 2.0
T_LOST_SEC = 2.0
LAMBDA_CROSS_VEH_S = 0.16
T_YELLOW_SEC = 3.5
T_ALL_RED_SEC = 2.0
G_MIN_SEC = 6.0

MU_MANEUVER = 1.705
SIGMA_MANEUVER = 0.35

def calc_transient_cross_delay(g_eff, g_norm=35.0, C=90.0, lam=0.16, s=0.50):
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

    R3 = C - g_norm
    arr_red_3 = lam * R3
    init_q3 = rem_q2
    peak_q3 = init_q3 + arr_red_3
    area_red_3 = 0.5 * (init_q3 + peak_q3) * R3
    t_clear_3 = peak_q3 / (s - lam)
    area_green_3 = 0.5 * peak_q3 * t_clear_3
    delay_c3 = area_red_3 + area_green_3

    return (delay_c1 + delay_c2 + delay_c3) / (3.0 * lam * C)

def simulate_causal_benchmark(rho_app=0.60, epsilon=0.05):
    controllers = [
        "1. Fixed-Distance (300m Static)",
        "2. Queue-Discharge (Obrusnik 2020)",
        "3. Reactive Observer (2s Sensor Polling)",
        "4. CC-HLP (Proposed Predictive)"
    ]

    metrics = {c: {
        "travel_time": [],
        "braking_episodes": [],
        "complete_stops": [],
        "clearance_violations": [],
        "cross_delay": [],
        "preempt_duration": []
    } for c in controllers}

    for seed in range(N_SEEDS):
        rng = np.random.default_rng(seed)

        # 1. Common traffic scenario parameters for this seed
        initial_queues = [int(rng.poisson(8.0)) for _ in range(NUM_INTERSECTIONS)]
        phase_elapsed = [float(rng.uniform(0.0, 20.0)) for _ in range(NUM_INTERSECTIONS)]
        v_desired = float(np.clip(rng.normal(V_EV_CRUISE_MEAN, 0.85), 17.5, 22.2))

        # 2. Common Random Numbers for driver behavioral realizations:
        # Pre-generate driver yielding attributes per vehicle so all 4 controllers face IDENTICAL traffic
        corridor_traffic = []
        for j in range(NUM_INTERSECTIONS):
            junction_pos = (j + 1) * BLOCK_DISTANCE_M
            N_init = initial_queues[j]
            j_vehs = []
            for k in range(1, N_init + 1):
                pos = junction_pos - (N_init - k + 1) * VEHICLE_LENGTH_M
                # Sample whether vehicle has app
                has_app = bool(rng.binomial(1, rho_app * 0.96))
                # Sample lateral gap availability
                has_gap = bool(rng.binomial(1, 0.82))
                # Sample compliance willingness
                is_compliant = bool(rng.binomial(1, 0.92))
                # Sample potential maneuver duration from lognormal
                dur = float(rng.lognormal(MU_MANEUVER, SIGMA_MANEUVER))
                j_vehs.append({
                    "id": k,
                    "pos": pos,
                    "has_app": has_app,
                    "has_gap": has_gap,
                    "is_compliant": is_compliant,
                    "dur": dur
                })
            corridor_traffic.append(j_vehs)

        # Evaluate each controller under the EXACT SAME scenario:
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

                # Vehicle state tracking:
                # Each vehicle yields if alerted, has gap, compliant, and deadline allows.
                # In this approach, when does vehicle receive alert?
                # App users receive push when EV enters block (t = clock).
                # Acoustic siren is heard when EV is within ~200m (dx <= 200m).
                veh_states = []
                for v in vehs_data:
                    # Initial alert receipt time:
                    if v["has_app"]:
                        t_alert = clock # instant digital push
                    else:
                        # Acoustic siren: arrives when EV gets within 180m of vehicle
                        d_to_veh = v["pos"] - ev_pos
                        t_siren_reach = clock + max(0.0, (d_to_veh - 180.0) / max(ev_speed, 5.0))
                        t_alert = t_siren_reach

                    # Deadline feasibility:
                    # Vehicle position relative to EV at alert instant
                    ev_pos_at_alert = min(v["pos"] - 15.0, ev_pos + (t_alert - clock) * ev_speed)
                    avail_dist = v["pos"] - ev_pos_at_alert - 15.0
                    avail_time = avail_dist / max(ev_speed, 5.0)

                    will_yield = v["has_gap"] and v["is_compliant"] and (v["dur"] <= avail_time) and (avail_time > 0.0)
                    t_vacate = (t_alert + v["dur"]) if will_yield else float('inf')

                    veh_states.append({
                        "id": v["id"],
                        "pos": v["pos"],
                        "will_yield": will_yield,
                        "t_alert": t_alert,
                        "t_vacate": t_vacate
                    })

                # Preemption Trigger Decision Logic:
                eta_j = (junction_pos - ev_pos) / max(ev_speed, 5.0)

                if c_idx == 0:
                    # 1. Fixed-Distance: Trigger when dist <= 300m
                    t_lead = min(eta_j, 300.0 / max(ev_speed, 5.0))
                    preempt_start = clock + (eta_j - t_lead)

                elif c_idx == 1:
                    # 2. Pure Queue-Discharge (Obrusnik 2020)
                    # Assumes P_yield = 0; flushes entire N_init through green
                    t_clear_plan = T_LOST_SEC + N_init * HEADWAY_S if N_init > 0 else 0.0
                    t_lead = min(eta_j, t_clear_plan + t_transition)
                    preempt_start = clock + (eta_j - t_lead)

                elif c_idx == 2:
                    # 3. Strictly Causal Sensor-Driven Reactive Observer (2s Polling)
                    # Polls approach at t_poll = clock, clock+2, clock+4, ...
                    # Counts vehicles where t_poll < t_vacate (currently still in lane)
                    # Triggers at first t_poll where remaining ETA <= required clearance lead time
                    triggered = False
                    preempt_start = clock + eta_j # default at arrival if never triggered
                    t_poll = clock
                    while t_poll <= clock + eta_j:
                        eta_poll = max(0.0, (junction_pos - (ev_pos + (t_poll - clock) * ev_speed)) / max(ev_speed, 5.0))
                        # Count vehicles STILL occupying the lane at this exact timestamp:
                        n_detected = sum(1 for vs in veh_states if t_poll < vs["t_vacate"])
                        t_clear_obs = T_LOST_SEC + n_detected * HEADWAY_S if n_detected > 0 else 0.0
                        lead_needed = t_clear_obs + t_transition

                        if eta_poll <= lead_needed:
                            preempt_start = t_poll
                            triggered = True
                            break
                        t_poll += 2.0 # 2.0s sensor polling interval

                    if not triggered:
                        preempt_start = clock + eta_j

                elif c_idx == 3:
                    # 4. Proposed CC-HLP (Predictive Chance-Constrained)
                    # Evaluates individual yielding probability chain for all vehicles:
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

                    # Exact discrete Poisson-Binomial quantile over residual blockers:
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

                # Signal Execution:
                green_display = preempt_start + t_transition

                # Physical Stopline Queue Clearance Trace:
                # When green displays, vehicles discharge sequentially unless they vacate!
                # Compute exact time stopline becomes clear:
                t_lane_clear = green_display
                discharged_count = 0
                for vs in veh_states:
                    if vs["will_yield"]:
                        # Vehicle will vacate at vs["t_vacate"]
                        # It blocks until min(vs["t_vacate"], discharge_time)
                        t_discharge_if_stayed = green_display + T_LOST_SEC + (discharged_count + 1) * HEADWAY_S
                        if vs["t_vacate"] < t_discharge_if_stayed:
                            # Vacated before its turn to discharge!
                            t_clear_this = vs["t_vacate"]
                        else:
                            # Discharged across stopline
                            discharged_count += 1
                            t_clear_this = t_discharge_if_stayed
                    else:
                        # Must discharge across stopline
                        discharged_count += 1
                        t_clear_this = green_display + T_LOST_SEC + discharged_count * HEADWAY_S

                    t_lane_clear = max(t_lane_clear, t_clear_this)

                # Check Clearance Headroom Violation:
                ev_arrival_expected = clock + eta_j
                if ev_arrival_expected < t_lane_clear:
                    tot_clearance_violations += 1

                # Continuous Microscopic Kinematic Integration (dt = 0.1s):
                dt = 0.1
                t_sim = clock
                x_sim = ev_pos
                v_sim = ev_speed
                in_braking_episode = False
                braking_episodes_at_junction = 0
                stopped_at_junction = False

                while x_sim < junction_pos:
                    dist_to_stopline = junction_pos - x_sim
                    
                    # Stopline is obstructed if signal is not green OR queue has not cleared:
                    is_stopline_blocked = (t_sim < green_display) or (t_sim < t_lane_clear)

                    if is_stopline_blocked and dist_to_stopline < 75.0:
                        # Deceleration needed
                        target_decel = -min(B_EV_EMERGENCY_MS2, max(B_EV_SERVICE_MS2, (v_sim ** 2) / (2.0 * max(8.0, dist_to_stopline))))
                        a_sim = target_decel
                        
                        if a_sim <= -2.0:
                            if not in_braking_episode:
                                in_braking_episode = True
                                braking_episodes_at_junction += 1
                        else:
                            in_braking_episode = False

                        v_sim = max(0.0, v_sim + a_sim * dt)
                        if v_sim < 0.05:
                            stopped_at_junction = True
                            v_sim = 0.0
                            if is_stopline_blocked:
                                t_sim += dt
                                continue
                    else:
                        # Clear road: accelerate back to desired cruising speed
                        in_braking_episode = False
                        if v_sim < v_desired:
                            a_sim = min(A_EV_MAX_MS2, (v_desired - v_sim) / dt)
                            v_sim = min(v_desired, v_sim + a_sim * dt)

                    x_sim += v_sim * dt
                    t_sim += dt

                tot_braking_episodes += braking_episodes_at_junction
                if stopped_at_junction:
                    tot_complete_stops += 1

                traversal_time = t_sim - clock

                # Preemption ends when EV clears junction (+2.0s clearance)
                preempt_end = t_sim + 2.0
                junc_preempt = max(0.0, preempt_end - preempt_start)
                tot_preempt_duration += junc_preempt

                # Cross-street delay:
                stolen_g = max(0.0, junc_preempt - t_transition)
                g_eff = max(G_MIN_SEC, G_CROSS_NOMINAL - stolen_g)
                tot_cross_delay += calc_transient_cross_delay(g_eff)

                # Advance clock and position:
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

    return metrics

metrics = simulate_causal_benchmark(rho_app=0.60, epsilon=0.05)

print("=" * 142)
print("FULLY CAUSAL BENCHMARK (COMMON RANDOM NUMBERS, 50 SEEDS, RHO=0.60, EPS=0.05, DDOF=1)")
print("=" * 142)
print(f"| {'Controller Strategy':<36} | {'EV Travel Time':<17} | {'Braking Episodes':<17} | {'Complete Stops':<15} | {'Clearance Viols':<16} | {'Cross Delay':<16} | {'Preempt Time':<16} |")
print("-" * 142)

for c in metrics:
    t_m, t_s = np.mean(metrics[c]["travel_time"]), np.std(metrics[c]["travel_time"], ddof=1)
    b_m, b_s = np.mean(metrics[c]["braking_episodes"]), np.std(metrics[c]["braking_episodes"], ddof=1)
    s_m, s_s = np.mean(metrics[c]["complete_stops"]), np.std(metrics[c]["complete_stops"], ddof=1)
    v_m, v_s = np.mean(metrics[c]["clearance_violations"]), np.std(metrics[c]["clearance_violations"], ddof=1)
    d_m, d_s = np.mean(metrics[c]["cross_delay"]), np.std(metrics[c]["cross_delay"], ddof=1)
    p_m, p_s = np.mean(metrics[c]["preempt_duration"]), np.std(metrics[c]["preempt_duration"], ddof=1)

    t_str = f"{t_m:.1f}s (±{t_s:.1f})"
    b_str = f"{b_m:.2f} (±{b_s:.2f})"
    s_str = f"{s_m:.2f} (±{s_s:.2f})"
    v_str = f"{v_m:.2f} (±{v_s:.2f})"
    d_str = f"{d_m:.1f}s (±{d_s:.1f})"
    p_str = f"{p_m:.1f}s (±{p_s:.1f})"

    print(f"| {c:<36} | {t_str:<17} | {b_str:<17} | {s_str:<15} | {v_str:<16} | {d_str:<16} | {p_str:<16} |")
print("=" * 142)

c_prop = "4. CC-HLP (Proposed Predictive)"
c_fix = "1. Fixed-Distance (300m Static)"
c_obr = "2. Queue-Discharge (Obrusnik 2020)"
c_rea = "3. Reactive Observer (2s Sensor Polling)"

d_prop = np.mean(metrics[c_prop]["cross_delay"])
d_fix = np.mean(metrics[c_fix]["cross_delay"])
d_obr = np.mean(metrics[c_obr]["cross_delay"])
d_rea = np.mean(metrics[c_rea]["cross_delay"])

p_prop = np.mean(metrics[c_prop]["preempt_duration"])
p_obr = np.mean(metrics[c_obr]["preempt_duration"])
p_rea = np.mean(metrics[c_rea]["preempt_duration"])

print("\n--- STATISTICAL COMPARISONS & PAIRED AUDIT ---")
print(f"Delay Improvement vs Obrusnik:       {((d_obr - d_prop) / d_obr)*100:.2f}% (Preemption duration reduced by {p_obr - p_prop:.1f}s, {((p_obr - p_prop)/p_obr)*100:.1f}%)")
print(f"Delay Improvement vs Reactive:       {((d_rea - d_prop) / d_rea)*100:.2f}% (Preemption duration reduced by {p_rea - p_prop:.1f}s, {((p_rea - p_prop)/p_rea)*100:.1f}%)")
print(f"Per-junction preemption duration reduction vs Obrusnik: {(p_obr - p_prop) / 5.0:.2f} s/junction")
print(f"Per-junction preemption duration reduction vs Reactive: {(p_rea - p_prop) / 5.0:.2f} s/junction")
