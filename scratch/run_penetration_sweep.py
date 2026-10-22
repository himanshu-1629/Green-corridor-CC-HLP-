import numpy as np
import math

np.random.seed(42)
N_SEEDS = 30

CORRIDOR_LENGTH_M = 3200.0
NUM_INTERSECTIONS = 5
BLOCK_DISTANCE_M = CORRIDOR_LENGTH_M / NUM_INTERSECTIONS
V_EV_CRUISE_MEAN = 20.0
A_EV_MAX_MS2 = 2.2
Q_SAT_VEH_S = 0.50
HEADWAY_S = 2.0
T_LOST_SEC = 2.0
LAMBDA_CROSS_VEH_S = 0.16
C_CYCLE = 90.0
G_CROSS_NOMINAL = 35.0
T_YELLOW_SEC = 3.5
T_ALL_RED_SEC = 2.0
G_MIN_SEC = 6.0

def calc_transient_delay(g_eff, g_norm=35.0, C=90.0, lam=0.16, s=0.50):
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

    return (delay_c1 + delay_c2 + delay_c3) / (3 * lam * C)

print(f"{'Penetration (rho)':<20} | {'CC-HLP Delay':<15} | {'Preempt Time':<15} | {'Braking Events':<16} | {'Complete Stops':<15}")
print("-" * 90)

for rho in [0.0, 0.20, 0.40, 0.60, 0.80, 1.0]:
    delays = []
    preempts = []
    braking = []
    stops = []

    for seed in range(N_SEEDS):
        rng = np.random.default_rng(seed)
        initial_queues = [int(rng.poisson(9.0)) for _ in range(NUM_INTERSECTIONS)]
        phase_elapsed = [float(rng.uniform(0.0, 20.0)) for _ in range(NUM_INTERSECTIONS)]
        v_ev_desired = float(np.clip(rng.normal(V_EV_CRUISE_MEAN, 0.85), 17.5, 22.2))

        current_time = 0.0
        ev_pos = 0.0
        ev_speed = v_ev_desired
        b_count = 0
        s_count = 0
        tot_preempt = 0.0
        tot_delay = 0.0

        for j in range(NUM_INTERSECTIONS):
            junction_pos = (j + 1) * BLOCK_DISTANCE_M
            dist = junction_pos - ev_pos
            N_init = initial_queues[j]
            g_el = phase_elapsed[j]
            t_transition = max(0.0, G_MIN_SEC - g_el) + T_YELLOW_SEC + T_ALL_RED_SEC

            p_yield_list = []
            for i in range(1, N_init + 1):
                veh_pos = junction_pos - (N_init - i + 1) * 7.5
                dx = max(15.0, veh_pos - ev_pos)
                p_acoustic = 1.0 / (1.0 + math.exp((dx - 180.0) / 30.0))
                p_mobile = rho * 0.96
                p_alert = 1.0 - (1.0 - p_mobile) * (1.0 - p_acoustic)
                p_gap = 0.82
                c_base = 0.92
                dt_deadline = max(0.1, (dx - 15.0) / max(ev_speed, 5.0))
                z = (math.log(dt_deadline) - 1.705) / 0.35
                p_feas = 0.5 * (1.0 + math.erf(z / math.sqrt(2.0)))
                p_i = p_alert * c_base * p_gap * p_feas
                p_yield_list.append(float(np.clip(p_i, 0.0, 0.98)))

            actual_yielded = sum(int(rng.binomial(1, p)) for p in p_yield_list)
            actual_rem_queue = max(0, N_init - actual_yielded)
            eta_j = dist / max(ev_speed, 5.0)

            # CC-HLP 95% quantile
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
                if cdf >= 0.95:
                    n_crit = k_idx
                    break

            t_clear_pred = T_LOST_SEC + n_crit * HEADWAY_S if n_crit > 0 else 0.0
            trigger_horizon = t_clear_pred + t_transition
            t_trigger_lead = min(eta_j, trigger_horizon)
            preempt_start = current_time + (eta_j - t_trigger_lead)

            green_display = preempt_start + t_transition
            ev_arrival = current_time + eta_j
            actual_clear = T_LOST_SEC + actual_rem_queue * HEADWAY_S if actual_rem_queue > 0 else 0.0
            queue_cleared = green_display + actual_clear

            headroom = ev_arrival - queue_cleared
            if headroom < 0.0:
                unmet = abs(headroom)
                b_count += 1
                if unmet > 3.0:
                    s_count += 1
                    t_accel = v_ev_desired / A_EV_MAX_MS2
                    d_accel = 0.5 * A_EV_MAX_MS2 * (t_accel ** 2)
                    d_cruise = max(0.0, BLOCK_DISTANCE_M - d_accel)
                    trav_time = unmet + t_accel + (d_cruise / v_ev_desired)
                else:
                    t_rec = (v_ev_desired - 10.0) / A_EV_MAX_MS2
                    trav_time = eta_j + unmet + (0.5 * t_rec)
            else:
                trav_time = eta_j + 0.4

            preempt_end = current_time + trav_time + 2.0
            junc_preempt = max(0.0, preempt_end - preempt_start)
            tot_preempt += junc_preempt

            stolen_g = max(0.0, junc_preempt - t_transition)
            g_eff = max(G_MIN_SEC, G_CROSS_NOMINAL - stolen_g)
            tot_delay += calc_transient_delay(g_eff)

            current_time += trav_time
            ev_pos = junction_pos
            ev_speed = v_ev_desired

        delays.append(tot_delay / NUM_INTERSECTIONS)
        preempts.append(tot_preempt)
        braking.append(b_count)
        stops.append(s_count)

    d_m, d_s = np.mean(delays), np.std(delays)
    p_m, p_s = np.mean(preempts), np.std(preempts)
    b_m = np.mean(braking)
    s_m = np.mean(stops)
    print(f"rho = {rho:<14.2f} | {d_m:.1f}s (±{d_s:.1f})   | {p_m:.1f}s (±{p_s:.1f})   | {b_m:.2f}             | {s_m:.2f}")

