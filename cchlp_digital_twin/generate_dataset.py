#!/usr/bin/env python3
"""
STEP 1: Empirical Dataset Generator for Driver Yielding Feasibility
Generates 50,000 calibrated human-driver encounters based on:
- Green (2000) & Taoka (1989): Lognormal Perception-Reaction Time
- Lidestam et al. (2020): In-cabin participatory alert dynamics
- HCM (2016) & Gipps (1986): Gap-acceptance lane-changing feasibility
"""

import numpy as np
import pandas as pd
import os

def generate_driver_dataset(n_samples=50000, seed=42):
    np.random.seed(seed)
    print(f"Generating {n_samples} driver encounter scenarios...")

    # Feature 1: Distance to Emergency Vehicle (EV) [meters]: 20m to 450m
    d_ev = np.random.uniform(20.0, 450.0, n_samples)

    # Feature 2: EV Approach Velocity [m/s]: 8 m/s (28 km/h) to 32 m/s (115 km/h)
    v_ev = np.random.uniform(8.0, 32.0, n_samples)

    # Feature 3: Time-to-Deadline until EV reaches the driver [seconds]
    t_deadline = d_ev / v_ev

    # Feature 4: Queue Position (Rank from stopline): 1 (front) to 25 (back)
    queue_pos = np.random.randint(1, 26, n_samples)
    queue_norm = queue_pos / 25.0

    # Feature 5: Adjacent Lane Gap [meters]: 1.5m (jammed) to 18.0m (clear)
    gap_adj = np.random.uniform(1.5, 18.0, n_samples)

    # Feature 6: Participatory App Alert Channel: 1 = Mobile App + Siren, 0 = Siren Only
    # Simulates ~60% participatory adoption
    has_app_alert = (np.random.rand(n_samples) < 0.60).astype(np.float32)

    # Feature 7: Historical Driver Latency Percentile [0.1 = fast, 0.9 = sluggish]
    driver_trait = np.random.beta(2, 2, n_samples)

    # Feature 8: Received Siren Loudness [dB]: Inverse-square law with background noise
    # L = 110 dB @ 1m, ambient noise ~ 65 dB
    siren_db = np.clip(110.0 - 20.0 * np.log10(np.maximum(10.0, d_ev)), 55.0, 95.0)

    # -------------------------------------------------------------
    # GROUND TRUTH DETERMINATION (Physics & Human Factors Engine)
    # -------------------------------------------------------------
    # Unalerted drivers (siren only): Median PRT ~ 5.5s (mu=1.705, sigma=0.35)
    # Alerted drivers (mobile app): Median PRT ~ 2.4s (mu=0.875, sigma=0.30)
    mu_prt = np.where(has_app_alert == 1, 0.875, 1.705)
    sigma_prt = np.where(has_app_alert == 1, 0.30, 0.35)
    raw_prt = np.random.lognormal(mu_prt, sigma_prt)

    # Steering & lateral transition execution time ~ 2.8s
    t_maneuver = raw_prt + 2.8

    # Gap acceptance criterion: Need at least 4.5m space in adjacent lane
    gap_sufficient = (gap_adj >= 4.5)

    # Time feasibility: Must complete maneuver before EV arrives
    time_sufficient = (t_maneuver <= t_deadline)

    # Queue penalty: Front 2 cars near stopline have tighter turning angles
    queue_penalty = np.where(queue_pos <= 2, 0.82, 1.0)

    # Ground truth binary label: 1 = Successfully Yielded, 0 = Remained Blocker
    success_prob = np.where(gap_sufficient & time_sufficient, 0.94 * queue_penalty, 0.08)
    y_label = (np.random.rand(n_samples) < success_prob).astype(np.int64)

    # Assemble into DataFrame
    df = pd.DataFrame({
        'dist_to_ev_m': np.round(d_ev, 2),
        'ev_speed_ms': np.round(v_ev, 2),
        'time_deadline_s': np.round(t_deadline, 2),
        'queue_rank_norm': np.round(queue_norm, 3),
        'adjacent_gap_m': np.round(gap_adj, 2),
        'has_app_alert': has_app_alert,
        'driver_trait': np.round(driver_trait, 3),
        'siren_loudness_db': np.round(siren_db, 2),
        'yielded_label': y_label
    })

    out_dir = os.path.dirname(os.path.abspath(__file__))
    out_csv = os.path.join(out_dir, "driver_yielding_dataset.csv")
    df.to_csv(out_csv, index=False)

    print(f"Dataset successfully created: {out_csv}")
    print(f"Total Samples: {len(df):,}")
    print(f"Class Balance: Yielded (1) = {df['yielded_label'].sum():,} ({df['yielded_label'].mean()*100:.1f}%), Blockers (0) = {(len(df) - df['yielded_label'].sum()):,}")
    print("\nSample Data Head:")
    print(df.head(5))

if __name__ == '__main__':
    generate_driver_dataset()
