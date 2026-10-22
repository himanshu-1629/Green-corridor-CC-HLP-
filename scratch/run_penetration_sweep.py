"""
Audited Sensitivity and Penetration Sweep Engine for CC-HLP.
Evaluates:
1. Risk Tolerance Epsilon Sweep: epsilon in [0.01, 0.03, 0.05, 0.08, 0.10]
2. Mobile App Adoption Penetration Sweep: rho_app in [0.00, 0.20, 0.40, 0.60, 0.80, 1.00]
Using Pinned Monte Carlo Seeds 1001-1050 (N=50).
"""

import os
import sys
import numpy as np
import math

sys.path.append(os.path.abspath(os.path.dirname(__file__)))
from run_four_controller_ablation import run_audited_benchmark, SEEDS, N_SEEDS

def run_sensitivity_sweeps():
    print("=" * 90)
    print("RUNNING RISK TOLERANCE (EPSILON) SWEEP (rho_app = 0.60)")
    print("=" * 90)
    epsilons = [0.01, 0.03, 0.05, 0.08, 0.10]
    for eps in epsilons:
        metrics, _ = run_audited_benchmark(rho_app=0.60, epsilon=eps)
        c = "4. CC-HLP (Proposed Predictive)"
        cd_m, cd_s = np.mean(metrics[c]["cross_delay"]), np.std(metrics[c]["cross_delay"], ddof=1)
        pr_m, pr_s = np.mean(metrics[c]["preempt_duration"]), np.std(metrics[c]["preempt_duration"], ddof=1)
        br_m, br_s = np.mean(metrics[c]["braking_episodes"]), np.std(metrics[c]["braking_episodes"], ddof=1)
        st_m, st_s = np.mean(metrics[c]["complete_stops"]), np.std(metrics[c]["complete_stops"], ddof=1)
        print(f"epsilon = {eps:.2f} | Delay: {cd_m:.1f} ± {cd_s:.1f} s/veh | Preempt Green: {pr_m:.1f} ± {pr_s:.1f} s | Decel: {br_m:.2f} ± {br_s:.2f} | Stops: {st_m:.2f} ± {st_s:.2f}")

    print("\n" + "=" * 90)
    print("RUNNING APP PENETRATION (RHO_APP) SWEEP (epsilon = 0.05)")
    print("=" * 90)
    rhos = [0.00, 0.20, 0.40, 0.60, 0.80, 1.00]
    for rho in rhos:
        metrics, _ = run_audited_benchmark(rho_app=rho, epsilon=0.05)
        c = "4. CC-HLP (Proposed Predictive)"
        cd_m, cd_s = np.mean(metrics[c]["cross_delay"]), np.std(metrics[c]["cross_delay"], ddof=1)
        pr_m, pr_s = np.mean(metrics[c]["preempt_duration"]), np.std(metrics[c]["preempt_duration"], ddof=1)
        br_m, br_s = np.mean(metrics[c]["braking_episodes"]), np.std(metrics[c]["braking_episodes"], ddof=1)
        print(f"rho = {rho:.2f} | Delay: {cd_m:.1f} ± {cd_s:.1f} s/veh | Preempt Green: {pr_m:.1f} ± {pr_s:.1f} s | Decel: {br_m:.2f} ± {br_s:.2f}")

if __name__ == "__main__":
    run_sensitivity_sweeps()
