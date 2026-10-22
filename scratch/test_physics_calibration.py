import numpy as np
import math

np.random.seed(42)
N_SEEDS = 50

CORRIDOR_LENGTH_M = 3200.0
NUM_INTERSECTIONS = 5
BLOCK_DISTANCE_M = CORRIDOR_LENGTH_M / NUM_INTERSECTIONS # 640m

# Kinematics
V_EV_CRUISE_MEAN = 20.0       # 72 km/h
A_EV_MAX_MS2 = 2.2            # Max acceleration
B_EV_COMFORT_MS2 = 2.5        # Service braking
B_EV_EMERGENCY_MS2 = 4.5      # Emergency braking limit

# Traffic parameters
Q_SAT_VEH_S = 0.5             # 1800 veh/h saturation flow
LAMBDA_CROSS_VEH_S = 0.15     # 540 veh/h cross-street flow
C_CYCLE = 90.0                # Cycle length
G_CROSS_NOMINAL = 35.0        # Cross-street nominal green
T_LOST_SEC = 2.0              # Startup lost time
T_YELLOW_SEC = 3.5            # Yellow clearance
T_ALL_RED_SEC = 2.0           # All-red clearance
G_MIN_SEC = 6.0               # Minimum green
HEADWAY_S = 2.0               # Saturation headway

def simulate_benchmark(rho_app=0.35):
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
        "preempt_duration_total": [],
        "cycle_failures": [],
        "cc_violations": []
    } for c in controllers}

    for seed in range(N_SEEDS):
        rng = np.random.default_rng(seed)

        # Ambient queue lengths at stop lines: Poisson(lambda=6.0)
        initial_queues = [int(rng.poisson(6.0)) for _ in range(NUM_INTERSECTIONS)]
        
        # Cross-street elapsed green time when EV enters decision window: Uniform(0, 20s)
        phase_elapsed = [float(rng.uniform(0.0, 20.0)) for _ in range(NUM_INTERSECTIONS)]

        # EV desired cruising speed with human driver variation: Normal(20.0, 1.2 m/s)
        v_ev_desired = float(np.clip(rng.normal(V_EV_CRUISE_MEAN, 1.0), 17.5, 22.2))

        for c_idx, c_name in enumerate(controllers):
            current_time = 0.0
            ev_pos = 0.0
            ev_speed = v_ev_desired
            
            braking_events = 0
            complete_stops = 0
            cc_violations = 0
            corridor_preempt_duration = 0.0
            total_cross_delay_at_intersections = 0.0
            total_cycle_failures = 0

            for j in range(NUM_INTERSECTIONS):
                junction_pos = (j + 1) * BLOCK_DISTANCE_M
                dist_to_junction = junction_pos - ev_pos
                
                N_init = initial_queues[j]
                g_el = phase_elapsed[j]
                
                # Signal transition duration to terminate conflicting cross-street phase:
                t_transition = max(0.0, G_MIN_SEC - g_el) + T_YELLOW_SEC + T_ALL_RED_SEC
                
                # Compute individual yielding probabilities:
                p_yield_list = []
                for i in range(1, N_init + 1):
                    veh_pos = junction_pos - (N_init - i + 1) * 7.5
                    dx = max(15.0, veh_pos - ev_pos)
                    
                    # Attention decay kernel
                    p_att = 1.0 - math.exp(-280.0 / dx)
                    # Gap acceptance
                    p_gap = math.exp(-0.20 * 3.5) # Poisson gap in target lane
                    # Base compliance with app penetration rho_app
                    p_behav = rho_app * 0.95 * p_att * 0.85 * p_gap
                    
                    # Deadline feasibility: maneuver duration Lognormal(1.705, 0.35)
                    dt_deadline = max(0.1, (dx - 15.0) / max(ev_speed, 5.0))
                    z = (math.log(dt_deadline) - 1.705) / 0.35
                    p_feas = 0.5 * (1.0 + math.erf(z / math.sqrt(2.0)))
                    
                    p_yield_list.append(float(np.clip(p_behav * p_feas, 0.0, 0.98)))

                # Sample actual yielding outcomes for this seed:
                actual_yielded = sum(int(rng.binomial(1, p)) for p in p_yield_list)
                actual_rem_queue = max(0, N_init - actual_yielded)

                # ETA to junction at current speed:
                eta_j = dist_to_junction / max(ev_speed, 5.0)

                # Controller Preemption Timing Decision:
                if c_idx == 0:
                    # 1. Fixed-Distance: Static 300m trigger distance
                    d_trigger = 300.0
                    t_trigger_before_arrival = min(eta_j, d_trigger / max(ev_speed, 5.0))
                    preempt_start_time = current_time + (eta_j - t_trigger_before_arrival)
                    scheduled_queue = N_init

                elif c_idx == 1:
                    # 2. Queue-Discharge (Obrusnik et al. 2020)
                    # Assumes P_yield = 0; flushes entire observed initial queue through green
                    t_clear_plan = T_LOST_SEC + N_init * HEADWAY_S if N_init > 0 else 0.0
                    trigger_horizon = t_clear_plan + t_transition
                    t_trigger_before_arrival = min(eta_j, trigger_horizon)
                    preempt_start_time = current_time + (eta_j - t_trigger_before_arrival)
                    scheduled_queue = N_init

                elif c_idx == 2:
                    # 3. Reactive Observer with Yielding
                    # Senses yielding reactively. Due to sensor lag & maneuver duration,
                    # observes only yielding that has completed prior to decision instant:
                    observed_yielded = int(actual_yielded * 0.45)
                    observed_queue = max(0, N_init - observed_yielded)
                    t_clear_obs = T_LOST_SEC + observed_queue * HEADWAY_S if observed_queue > 0 else 0.0
                    trigger_horizon = t_clear_obs + t_transition
                    t_trigger_before_arrival = min(eta_j, trigger_horizon)
                    preempt_start_time = current_time + (eta_j - t_trigger_before_arrival)
                    scheduled_queue = observed_queue

                elif c_idx == 3:
                    # 4. CC-HLP (Proposed Chance-Constrained Predictive)
                    # Computes exact discrete Poisson-Binomial 99% quantile over residual blockers:
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
                        if cdf >= 0.99:
                            n_crit = k_idx
                            break
                    
                    t_clear_pred = T_LOST_SEC + n_crit * HEADWAY_S if n_crit > 0 else 0.0
                    trigger_horizon = t_clear_pred + t_transition
                    t_trigger_before_arrival = min(eta_j, trigger_horizon)
                    preempt_start_time = current_time + (eta_j - t_trigger_before_arrival)
                    scheduled_queue = n_crit

                # Signal state execution
                green_display_time = preempt_start_time + t_transition
                ev_arrival_time = current_time + eta_j
                
                # Actual queue dissipation:
                actual_clear_time = T_LOST_SEC + actual_rem_queue * HEADWAY_S if actual_rem_queue > 0 else 0.0
                queue_cleared_time = green_display_time + actual_clear_time

                # Check clearance vs EV arrival:
                time_headroom = ev_arrival_time - queue_cleared_time

                if time_headroom < 0.0:
                    # Conflict! Queue still clearing when EV arrives
                    cc_violations += 1
                    unmet_delay = abs(time_headroom)
                    braking_events += 1

                    if unmet_delay > 3.0:
                        # Severe obstruction: EV decelerates to full stop
                        complete_stops += 1
                        t_accel = v_ev_desired / A_EV_MAX_MS2
                        d_accel = 0.5 * A_EV_MAX_MS2 * (t_accel ** 2)
                        d_remaining = max(0.0, BLOCK_DISTANCE_M - d_accel)
                        t_segment = unmet_delay + t_accel + (d_remaining / v_ev_desired)
                    else:
                        # Minor deceleration (speed dip to ~10 m/s and resume)
                        t_rec = (v_ev_desired - 10.0) / A_EV_MAX_MS2
                        t_segment = eta_j + unmet_delay + (0.5 * t_rec)
                else:
                    # Green corridor clear! Nominal cruise with small approach caution
                    t_caution = 0.5 # 0.5s brief verification lift
                    t_segment = eta_j + t_caution

                current_time += t_segment
                ev_pos = junction_pos
                ev_speed = v_ev_desired

                # Preemption duration: from trigger start until EV fully clears intersection (+2.0s clearance)
                preempt_end_time = current_time + 2.0
                junction_preempt_duration = max(0.0, preempt_end_time - preempt_start_time)
                corridor_preempt_duration += junction_preempt_duration

                # -------------------------------------------------------------
                # Cross-Street Delay Evaluation (Webster & HCM 6th Edition)
                # -------------------------------------------------------------
                # Preemption preempts cross-street green during this cycle:
                stolen_green = max(0.0, junction_preempt_duration - t_transition)
                g_eff = max(G_MIN_SEC, G_CROSS_NOMINAL - stolen_green)
                
                # Capacity of cross street during preemption cycle:
                c_preempt = Q_SAT_VEH_S * (g_eff / C_CYCLE)
                X_preempt = LAMBDA_CROSS_VEH_S / max(0.02, c_preempt)

                # Check if cycle failure occurred:
                if X_preempt >= 1.0:
                    total_cycle_failures += 1

                # HCM 6th Edition delay formulation:
                # d1: uniform delay
                g_C = g_eff / C_CYCLE
                d1 = (0.5 * C_CYCLE * ((1.0 - g_C) ** 2)) / (1.0 - min(0.99, g_C * min(X_preempt, 1.0)))
                
                # d2: incremental overflow delay (for oversaturated or stochastic queue)
                T_analysis = 0.25 # 15-minute analysis period in hours
                k_val = 0.50
                I_val = 1.0
                c_veh_h = c_preempt * 3600.0
                term_X = X_preempt - 1.0
                radicand = max(0.0, (term_X ** 2) + ((8.0 * k_val * I_val * X_preempt) / max(1.0, c_veh_h * T_analysis)))
                d2 = 900.0 * T_analysis * (term_X + math.sqrt(radicand))
                
                # Residual delay averaged over cross-street vehicles in the cycle:
                total_delay_veh = max(15.0, min(300.0, d1 + d2))
                total_cross_delay_at_intersections += total_delay_veh

            avg_cross_delay = total_cross_delay_at_intersections / NUM_INTERSECTIONS
            
            metrics[c_name]["ev_travel_time"].append(current_time)
            metrics[c_name]["ev_braking_events"].append(braking_events)
            metrics[c_name]["ev_complete_stops"].append(complete_stops)
            metrics[c_name]["cross_street_delay"].append(avg_cross_delay)
            metrics[c_name]["preempt_duration_total"].append(corridor_preempt_duration)
            metrics[c_name]["cycle_failures"].append(total_cycle_failures)
            metrics[c_name]["cc_violations"].append(cc_violations)

    return metrics

metrics = simulate_benchmark(rho_app=0.35)
print("=" * 125)
print("SIMULATION BENCHMARK RESULTS (50 SEEDS, RHO_APP = 0.35)")
print("=" * 125)
print(f"| {'Controller Strategy':<34} | {'EV Travel Time':<17} | {'Braking Events':<16} | {'Complete Stops':<15} | {'Cross Delay':<16} | {'Preempt Time':<16} |")
print("-" * 125)

for c in metrics:
    t_m, t_s = np.mean(metrics[c]["ev_travel_time"]), np.std(metrics[c]["ev_travel_time"])
    b_m, b_s = np.mean(metrics[c]["ev_braking_events"]), np.std(metrics[c]["ev_braking_events"])
    s_m, s_s = np.mean(metrics[c]["ev_complete_stops"]), np.std(metrics[c]["ev_complete_stops"])
    d_m, d_s = np.mean(metrics[c]["cross_street_delay"]), np.std(metrics[c]["cross_street_delay"])
    p_m, p_s = np.mean(metrics[c]["preempt_duration_total"]), np.std(metrics[c]["preempt_duration_total"])

    t_str = f"{t_m:.1f}s (±{t_s:.1f})"
    b_str = f"{b_m:.2f} (±{b_s:.2f})"
    s_str = f"{s_m:.2f} (±{s_s:.2f})"
    d_str = f"{d_m:.1f}s (±{d_s:.1f})"
    p_str = f"{p_m:.1f}s (±{p_s:.1f})"

    print(f"| {c:<34} | {t_str:<17} | {b_str:<16} | {s_str:<15} | {d_str:<16} | {p_str:<16} |")
print("=" * 125)
